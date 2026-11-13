// POS touch till: drawing and taps only. All business logic is in AL (codeunit "POS Till Controller").
// AL -> JS: Render(state), SetCatalog(catalog), ShowPicker(items), ShowInfo(text), ShowError(text), ShowChange(amount)
// JS -> AL: Command(name, payloadJson) via Microsoft.Dynamics.NAV.InvokeExtensibilityMethod
var PosTill = (function () {
    'use strict';

    var root = null;
    var ui = {};
    var state = emptyState();
    var catalog = { categories: [], items: [] };
    var category = 'ALL';
    var entry = '';
    var selected = 0;
    var followBackend = true;
    var overlay = null;
    var overlayTimer = null;
    var toastTimer = null;
    var busyTimer = null;

    function emptyState() {
        return {
            docNo: '', status: 'New', onHold: false, shiftNo: '', requireShift: false, cashier: '', workDate: '',
            lines: [], lineCount: 0, itemCount: 0, selectedLine: 0, total: 0, amountDue: 0, redemption: 0,
            paid: 0, stillToPay: 0, change: 0, payments: [], canComplete: false,
            loyalty: { enabled: false, phone: '', balance: 0, pointsToEarn: 0, pointsToRedeem: 0, maxRedeemable: 0, pointValue: 0 },
            mpesaPending: false, mpesaPhone: ''
        };
    }

    // ------------------------------------------------------------------ helpers

    function el(tag, cls, text) {
        var e = document.createElement(tag);
        if (cls) { e.className = cls; }
        if (text !== undefined && text !== null) { e.textContent = text; }
        return e;
    }

    function btn(label, cls, act, extra) {
        var b = el('button', cls || '', label);
        b.type = 'button';
        b.setAttribute('data-act', act);
        if (extra) {
            Object.keys(extra).forEach(function (k) { b.setAttribute('data-' + k, extra[k]); });
        }
        return b;
    }

    function money(n) {
        var v = Number(n) || 0;
        return v.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    }

    function qtyText(n) {
        var v = Number(n) || 0;
        return String(Math.round(v * 100000) / 100000);
    }

    function num(s) {
        var v = parseFloat(s);
        return isFinite(v) ? v : 0;
    }

    function send(name, payload) {
        // commands that change the lines move the highlight to the line AL reports
        followBackend = ['scan', 'addItem', 'setQty', 'recallDoc', 'deleteLine', 'newSale', 'hold', 'post'].indexOf(name) >= 0;
        setBusy(true);
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('Command', [name, JSON.stringify(payload || {})]);
    }

    function setBusy(on) {
        if (!root) { return; }
        if (busyTimer) { clearTimeout(busyTimer); busyTimer = null; }
        if (on) {
            root.classList.add('busy');
            busyTimer = setTimeout(function () { root.classList.remove('busy'); }, 30000);
        } else {
            root.classList.remove('busy');
        }
    }

    // Focus returns to the scan box after every tap so a USB/Bluetooth scanner always types there.
    // inputmode="none" keeps the on-screen keyboard closed for that automatic focus; tapping the
    // box itself switches to "text" so the cashier can type an item name.
    function focusScan() {
        if (overlay || !ui.scan) { return; }
        ui.scan.setAttribute('inputmode', 'none');
        try { ui.scan.focus({ preventScroll: true }); } catch (e) { ui.scan.focus(); }
    }

    function findLine(lineNo) {
        for (var i = 0; i < state.lines.length; i++) {
            if (state.lines[i].lineNo === lineNo) { return state.lines[i]; }
        }
        return null;
    }

    // ------------------------------------------------------------------ build

    function init(container) {
        root = container;
        root.innerHTML = '';
        var till = el('div', 'till');
        root.appendChild(till);

        // top bar
        var top = el('div', 'topbar');
        ui.title = el('span', 'title', 'Till');
        ui.noShift = el('span', 'noshift', '');
        ui.who = el('span', 'who', '');
        top.appendChild(ui.title);
        top.appendChild(ui.noShift);
        top.appendChild(el('span', 'spacer'));
        ui.who.className = 'who';
        top.appendChild(ui.who);
        ui.clock = el('span', 'clock', '');
        top.appendChild(ui.clock);
        top.appendChild(btn('New sale', '', 'newSale'));
        top.appendChild(btn('Recall', '', 'recall'));
        ui.shiftBtn = btn('Open shift', '', 'shift');
        top.appendChild(ui.shiftBtn);
        till.appendChild(top);

        var cols = el('div', 'cols');
        till.appendChild(cols);

        // left: cart
        var left = el('div', 'col');
        ui.scan = el('input', 'scan');
        ui.scan.type = 'text';
        ui.scan.placeholder = 'Scan barcode, or type item name (3*code for quantity)';
        ui.scan.autocomplete = 'off';
        ui.scan.setAttribute('autocapitalize', 'off');
        ui.scan.setAttribute('inputmode', 'none');
        ui.scan.addEventListener('pointerdown', function () {
            if (ui.scan.getAttribute('inputmode') === 'none') {
                ui.scan.setAttribute('inputmode', 'text');
                ui.scan.blur();
                setTimeout(function () { ui.scan.focus(); }, 0);
            }
        });
        ui.scan.addEventListener('keydown', function (e) {
            if (e.key === 'Enter') { e.preventDefault(); submitScan(); }
        });
        left.appendChild(ui.scan);
        ui.cart = el('div', 'box cart');
        left.appendChild(ui.cart);
        var totalBox = el('div', 'box totalbox');
        var tl = el('div', '');
        tl.appendChild(el('div', 'items', 'Total'));
        ui.items = el('div', 'items', '0 items');
        ui.total = el('div', 'big', '0.00');
        tl.appendChild(ui.items);
        totalBox.appendChild(tl);
        totalBox.appendChild(ui.total);
        left.appendChild(totalBox);
        var cartBtns = el('div', 'row3');
        cartBtns.appendChild(btn('Qty', '', 'qty'));
        cartBtns.appendChild(btn('Void line', 'danger', 'void'));
        cartBtns.appendChild(btn('Hold', '', 'hold'));
        left.appendChild(cartBtns);
        cols.appendChild(left);

        // middle: catalog + loyalty
        var mid = el('div', 'col');
        ui.chips = el('div', 'chips');
        mid.appendChild(ui.chips);
        ui.grid = el('div', 'box grid');
        mid.appendChild(ui.grid);
        var loy = el('div', 'box loyalty');
        var info = el('div', 'info');
        ui.loyPhone = el('span', 'phone', '');
        ui.loyBal = el('span', 'muted', '');
        ui.loyClear = btn('x', '', 'memberClear');
        ui.loyClear.style.minHeight = '36px';
        info.appendChild(ui.loyPhone);
        info.appendChild(ui.loyBal);
        info.appendChild(el('span', 'spacer'));
        info.appendChild(ui.loyClear);
        loy.appendChild(info);
        var lb = el('div', 'btns');
        ui.memberBtn = btn('Member', '', 'member');
        ui.redeemBtn = btn('Redeem pts', '', 'redeem');
        lb.appendChild(ui.memberBtn);
        lb.appendChild(ui.redeemBtn);
        loy.appendChild(lb);
        ui.loyBox = loy;
        mid.appendChild(loy);
        cols.appendChild(mid);

        // right: payment
        var right = el('div', 'col');
        var stats = el('div', 'box');
        var s1 = el('div', 'stat topay');
        s1.appendChild(el('span', 'label', 'Still to pay'));
        ui.toPay = el('span', 'val', '0.00');
        s1.appendChild(ui.toPay);
        stats.appendChild(s1);
        var s2 = el('div', 'stat small');
        s2.appendChild(el('span', 'label', 'Paid'));
        ui.paid = el('span', 'val', '0.00');
        s2.appendChild(ui.paid);
        stats.appendChild(s2);
        var s3 = el('div', 'stat change small');
        s3.appendChild(el('span', 'label', 'Change'));
        ui.change = el('span', 'val', '0.00');
        s3.appendChild(ui.change);
        stats.appendChild(s3);
        ui.redemptionRow = el('div', 'stat small');
        ui.redemptionRow.appendChild(el('span', 'label', 'Points discount'));
        ui.redemption = el('span', 'val', '0.00');
        ui.redemptionRow.appendChild(ui.redemption);
        stats.appendChild(ui.redemptionRow);
        ui.payments = el('div', 'payments', '');
        stats.appendChild(ui.payments);
        right.appendChild(stats);

        ui.entry = el('div', 'entry');
        ui.entryText = el('span', '', '0');
        ui.entry.appendChild(ui.entryText);
        ui.entry.appendChild(el('span', 'hint', 'keypad'));
        right.appendChild(ui.entry);

        var pad = el('div', 'keypad');
        ['7', '8', '9', 'back', '4', '5', '6', 'clear', '1', '2', '3', '.', '0', '00'].forEach(function (k) {
            if (k === 'back') { pad.appendChild(btn('⌫', '', 'key', { k: 'back' })); }
            else if (k === 'clear') { pad.appendChild(btn('C', '', 'key', { k: 'clear' })); }
            else { pad.appendChild(btn(k, '', 'key', { k: k })); }
        });
        right.appendChild(pad);

        var notes = el('div', 'notes');
        [100, 500, 1000].forEach(function (n) { notes.appendChild(btn(String(n), '', 'note', { amt: n })); });
        right.appendChild(notes);

        var pay = el('div', 'pay');
        pay.appendChild(btn('Cash', 'primary', 'cash'));
        pay.appendChild(btn('MPESA', 'primary', 'mpesa'));
        pay.appendChild(btn('Card', 'primary', 'card'));
        right.appendChild(pay);
        ui.mpesaCheck = btn('Check MPESA', 'mpesa-check', 'checkMpesa');
        right.appendChild(ui.mpesaCheck);
        ui.clearPay = btn('Clear payments', '', 'clearPayments');
        right.appendChild(ui.clearPay);
        ui.complete = btn('Complete sale', 'success complete', 'complete');
        right.appendChild(ui.complete);
        cols.appendChild(right);

        // events
        root.addEventListener('click', onClick);
        // keep the focus in the scan box: taps on buttons must not take it away
        root.addEventListener('mousedown', function (e) {
            if (e.target && e.target.closest && e.target.closest('button')) { e.preventDefault(); }
        });
        setInterval(updateClock, 15000);

        renderAll();
        focusScan();
    }

    // ------------------------------------------------------------------ rendering

    function renderAll() {
        renderTop();
        renderCart();
        renderTotals();
        renderLoyalty();
        renderPay();
        renderCatalog();
        updateEntry();
    }

    function updateClock() {
        if (!ui.clock) { return; }
        var d = new Date();
        var hh = ('0' + d.getHours()).slice(-2);
        var mm = ('0' + d.getMinutes()).slice(-2);
        ui.clock.textContent = (state.workDate ? state.workDate + '  ' : '') + hh + ':' + mm;
    }

    function renderTop() {
        var hasShift = !!state.shiftNo;
        ui.title.textContent = hasShift ? 'Till · Shift ' + state.shiftNo : 'Till';
        ui.noShift.textContent = hasShift ? '' : (state.requireShift ? '· No open shift' : '· No shift');
        ui.who.textContent = state.cashier || '';
        ui.shiftBtn.textContent = hasShift ? 'Close shift' : 'Open shift';
        ui.shiftBtn.className = hasShift ? '' : (state.requireShift ? 'danger' : '');
        updateClock();
    }

    function renderCart() {
        ui.cart.innerHTML = '';
        if (!state.lines.length) {
            ui.cart.appendChild(el('div', 'empty', 'Scan or tap an item to start the sale'));
            return;
        }
        state.lines.forEach(function (l) {
            var row = el('div', 'line' + (l.lineNo === selected ? ' sel' : ''));
            row.setAttribute('data-act', 'line');
            row.setAttribute('data-line', l.lineNo);
            row.appendChild(el('div', 'desc', l.description || l.itemNo));
            row.appendChild(el('div', 'amt', money(l.amount)));
            row.appendChild(el('div', 'qty', qtyText(l.qty) + ' × ' + money(l.unitPrice)));
            row.appendChild(el('div', ''));
            ui.cart.appendChild(row);
        });
        var selRow = ui.cart.querySelector('.line.sel');
        if (selRow && selRow.scrollIntoView) { selRow.scrollIntoView({ block: 'nearest' }); }
    }

    function renderTotals() {
        ui.total.textContent = money(state.amountDue);
        var n = state.itemCount || 0;
        ui.items.textContent = qtyText(n) + (n === 1 ? ' item' : ' items');
    }

    function renderLoyalty() {
        var l = state.loyalty || {};
        ui.loyBox.style.display = l.enabled ? '' : 'none';
        if (l.phone) {
            ui.loyPhone.textContent = l.phone;
            var t = l.balance + ' pts';
            if (l.pointsToRedeem) { t += ' · redeeming ' + l.pointsToRedeem; }
            if (l.pointsToEarn) { t += ' · earns ' + l.pointsToEarn; }
            ui.loyBal.textContent = t;
            ui.loyClear.style.display = '';
        } else {
            ui.loyPhone.textContent = 'No member';
            ui.loyBal.textContent = 'Type the phone number, then tap Member';
            ui.loyClear.style.display = 'none';
        }
        ui.redeemBtn.disabled = !l.phone;
    }

    function renderPay() {
        ui.toPay.textContent = money(state.stillToPay);
        ui.toPay.className = 'val' + (state.stillToPay > 0 ? ' due' : '');
        ui.paid.textContent = money(state.paid);
        ui.change.textContent = money(state.change);
        ui.change.className = 'val' + (state.change > 0 ? ' some' : '');
        ui.redemptionRow.style.display = state.redemption > 0 ? '' : 'none';
        ui.redemption.textContent = '-' + money(state.redemption);
        var parts = (state.payments || []).map(function (p) { return p.method + ' ' + money(p.amount); });
        ui.payments.textContent = parts.join('  ·  ');
        ui.payments.style.display = parts.length ? '' : 'none';
        ui.complete.disabled = !state.canComplete;
        ui.mpesaCheck.style.display = state.mpesaPending ? '' : 'none';
        ui.clearPay.style.display = parts.length ? '' : 'none';
    }

    function renderCatalog() {
        ui.chips.innerHTML = '';
        var cats = (catalog.categories || []).slice();
        cats.sort(function (a, b) { return String(a.description).localeCompare(String(b.description)); });
        var all = btn('All', 'chip' + (category === 'ALL' ? ' on' : ''), 'cat', { code: 'ALL' });
        ui.chips.appendChild(all);
        cats.forEach(function (c) {
            var label = c.description || (c.code === '' ? 'Other' : c.code);
            if (c.code === '') { label = 'Other'; }
            ui.chips.appendChild(btn(label, 'chip' + (category === c.code ? ' on' : ''), 'cat', { code: c.code }));
        });

        ui.grid.innerHTML = '';
        var items = (catalog.items || []).filter(function (i) { return category === 'ALL' || i.category === category; });
        items.sort(function (a, b) {
            if (a.sort !== b.sort) { return a.sort - b.sort; }
            return String(a.description).localeCompare(String(b.description));
        });
        if (!items.length) {
            ui.grid.appendChild(el('div', 'none', (catalog.items || []).length ? 'No items in this category.' :
                'No product buttons yet. On the Item Card, switch on POS Till Button.'));
            return;
        }
        items.forEach(function (i) {
            var t = btn('', 'tile', 'tile', { no: i.no });
            t.appendChild(el('span', 'name', i.description));
            t.appendChild(el('span', 'price', money(i.price)));
            ui.grid.appendChild(t);
        });
    }

    function updateEntry() {
        ui.entryText.textContent = entry === '' ? '0' : entry;
    }

    // ------------------------------------------------------------------ overlays

    function closeOverlay() {
        if (overlayTimer) { clearTimeout(overlayTimer); overlayTimer = null; }
        if (overlay && overlay.parentNode) { overlay.parentNode.removeChild(overlay); }
        overlay = null;
    }

    function openOverlay(dialog) {
        closeOverlay();
        overlay = el('div', 'overlay');
        overlay.appendChild(dialog);
        overlay.addEventListener('click', function (e) { if (e.target === overlay) { closeOverlay(); focusScan(); } });
        root.appendChild(overlay);
    }

    function toast(text, isError) {
        var old = root.querySelector('.toast');
        if (old) { old.parentNode.removeChild(old); }
        if (toastTimer) { clearTimeout(toastTimer); toastTimer = null; }
        if (!text) { return; }
        var t = el('div', 'toast' + (isError ? ' error' : ''), text);
        t.addEventListener('click', function () { if (t.parentNode) { t.parentNode.removeChild(t); } });
        root.appendChild(t);
        toastTimer = setTimeout(function () { if (t.parentNode) { t.parentNode.removeChild(t); } }, isError ? 9000 : 4000);
    }

    function confirmDialog(title, message, okLabel, onOk) {
        var d = el('div', 'dialog');
        d.appendChild(el('h2', '', title));
        d.appendChild(el('div', '', message));
        var a = el('div', 'actions');
        var cancel = btn('Cancel', '', 'dlgCancel');
        var ok = btn(okLabel, 'danger', 'dlgOk');
        a.appendChild(cancel);
        a.appendChild(ok);
        d.appendChild(a);
        d.addEventListener('click', function (e) {
            var b = e.target.closest ? e.target.closest('button') : null;
            if (!b) { return; }
            e.stopPropagation();
            var act = b.getAttribute('data-act');
            closeOverlay();
            if (act === 'dlgOk') { onOk(); }
            focusScan();
        });
        openOverlay(d);
    }

    function showPicker(items) {
        var d = el('div', 'dialog');
        var isHeld = items.length && items[0].kind === 'held';
        d.appendChild(el('h2', '', isHeld ? 'Held sales' : 'Choose the item'));
        var list = el('div', 'list');
        items.forEach(function (it) {
            var b = el('button', 'item', '');
            b.type = 'button';
            var left = el('span', '', it.title);
            var sub = el('span', 'sub', it.subtitle || '');
            left.appendChild(sub);
            b.appendChild(left);
            b.appendChild(el('span', '', money(it.amount)));
            b.setAttribute('data-id', it.id);
            b.setAttribute('data-kind', it.kind);
            b.setAttribute('data-qty', it.qty || 1);
            list.appendChild(b);
        });
        d.appendChild(list);
        var a = el('div', 'actions');
        a.appendChild(btn('Cancel', '', 'dlgCancel'));
        d.appendChild(a);
        d.addEventListener('click', function (e) {
            var b = e.target.closest ? e.target.closest('button') : null;
            if (!b) { return; }
            e.stopPropagation();
            var kind = b.getAttribute('data-kind');
            var id = b.getAttribute('data-id');
            var qty = num(b.getAttribute('data-qty')) || 1;
            closeOverlay();
            if (kind === 'item') { send('addItem', { itemNo: id, qty: qty }); }
            else if (kind === 'held') { send('recallDoc', { docNo: id }); }
            focusScan();
        });
        openOverlay(d);
    }

    function showChange(amount) {
        var d = el('div', 'dialog changebox');
        if (amount > 0) {
            d.appendChild(el('div', 'label', 'Give change:'));
            d.appendChild(el('div', 'amount', money(amount)));
        } else {
            d.appendChild(el('h2', '', 'Sale complete'));
        }
        var a = el('div', 'actions');
        a.appendChild(btn('OK', 'success', 'dlgCancel'));
        d.appendChild(a);
        d.addEventListener('click', function () { closeOverlay(); focusScan(); });
        openOverlay(d);
        if (!(amount > 0)) {
            overlayTimer = setTimeout(function () { closeOverlay(); focusScan(); }, 2000);
        }
    }

    // ------------------------------------------------------------------ actions

    function submitScan() {
        var t = ui.scan.value.replace(/^\s+|\s+$/g, '');
        ui.scan.value = '';
        closeOverlay();
        if (t) { send('scan', { text: t }); }
    }

    function takeEntry() {
        var v = entry;
        entry = '';
        updateEntry();
        return v;
    }

    function pressKey(k) {
        if (k === 'back') { entry = entry.slice(0, -1); }
        else if (k === 'clear') { entry = ''; }
        else if (k === '.') { if (entry.indexOf('.') < 0) { entry = (entry === '' ? '0' : entry) + '.'; } }
        else if (entry.length < 12) { entry = (entry === '0' && k !== '00') ? k : entry + k; if (entry === '00') { entry = '0'; } }
        updateEntry();
    }

    function onClick(e) {
        var t = e.target.closest ? e.target.closest('[data-act]') : null;
        if (!t || t.disabled) { return; }
        var act = t.getAttribute('data-act');
        var changed = true;

        switch (act) {
            case 'key': pressKey(t.getAttribute('data-k')); break;
            case 'note': send('payCash', { amount: Number(t.getAttribute('data-amt')) }); break;
            case 'cash': send('payCash', { amount: num(takeEntry()) }); break;
            case 'card': send('payCard', { amount: num(takeEntry()), reference: '' }); break;
            case 'mpesa': send('payMpesa', { phone: takeEntry() }); break;
            case 'checkMpesa': send('checkMpesa', {}); break;
            case 'clearPayments': send('clearPayments', {}); break;
            case 'complete': send('post', {}); break;
            case 'tile': send('addItem', { itemNo: t.getAttribute('data-no'), qty: 1 }); break;
            case 'cat': category = t.getAttribute('data-code'); renderCatalog(); break;
            case 'line':
                selected = Number(t.getAttribute('data-line'));
                renderCart();
                break;
            case 'qty':
                if (!selected || !findLine(selected)) { toast('Select a line first.', true); break; }
                var q = num(takeEntry());
                if (q <= 0) { toast('Enter the quantity on the keypad first.', true); break; }
                send('setQty', { lineNo: selected, qty: q });
                break;
            case 'void':
                if (!selected || !findLine(selected)) { toast('Select a line first.', true); break; }
                var ln = findLine(selected);
                var lineNo = selected;
                confirmDialog('Void line', 'Remove ' + qtyText(ln.qty) + ' × ' + (ln.description || ln.itemNo) + ' from the sale?', 'Remove', function () {
                    send('deleteLine', { lineNo: lineNo });
                });
                break;
            case 'hold': send('hold', {}); break;
            case 'recall': send('recall', {}); break;
            case 'newSale': send('newSale', {}); break;
            case 'shift': send(state.shiftNo ? 'closeShift' : 'openShift', {}); break;
            case 'member':
                var phone = takeEntry();
                if (!phone) { toast('Type the member phone number on the keypad first.', true); break; }
                send('loyaltyPhone', { phone: phone });
                break;
            case 'memberClear': send('loyaltyPhone', { phone: '' }); break;
            case 'redeem':
                var pts = Math.floor(num(takeEntry()));
                send('redeem', { points: pts });
                break;
            case 'dlgCancel': closeOverlay(); break;
            default: changed = false;
        }
        if (changed) { focusScan(); }
    }

    // ------------------------------------------------------------------ AL -> JS

    function render(s) {
        setBusy(false);
        state = s || emptyState();
        if (!state.lines) { state.lines = []; }
        if (!state.payments) { state.payments = []; }
        if (!state.loyalty) { state.loyalty = emptyState().loyalty; }
        // follow AL's selection after commands that change the lines; otherwise keep the cashier's tap
        if (followBackend || !findLine(selected)) { selected = state.selectedLine; }
        followBackend = true;
        if (!state.docNo) { entry = ''; selected = 0; }
        renderAll();
        focusScan();
    }

    function setCatalog(c) {
        catalog = c || { categories: [], items: [] };
        if (category !== 'ALL') {
            var exists = (catalog.categories || []).some(function (x) { return x.code === category; });
            if (!exists) { category = 'ALL'; }
        }
        renderCatalog();
    }

    return {
        init: init,
        render: render,
        setCatalog: setCatalog,
        showPicker: function (items) { setBusy(false); showPicker(items || []); },
        showInfo: function (text) { toast(text, false); },
        showError: function (text) { setBusy(false); toast(text, true); },
        showChange: function (amount) { setBusy(false); toast('', false); showChange(Number(amount) || 0); }
    };
})();

// Procedures called by AL (names as declared in the control add-in)
function Render(state) { PosTill.render(state); }
function SetCatalog(catalog) { PosTill.setCatalog(catalog); }
function ShowPicker(items) { PosTill.showPicker(items); }
function ShowInfo(text) { PosTill.showInfo(text); }
function ShowError(text) { PosTill.showError(text); }
function ShowChange(amount) { PosTill.showChange(amount); }
