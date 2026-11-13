// POS touch till: drawing and taps only. All business logic is in AL (codeunit "POS Till Controller").
// AL -> JS: Render(state), SetCatalog(catalog), ShowPicker(items), ShowInfo(text), ShowError(text), ShowChange(amount)
// JS -> AL: Command(name, payloadJson) via Microsoft.Dynamics.NAV.InvokeExtensibilityMethod
var PosTill = (function () {
    'use strict';

    // Product buttons (middle column) are hidden for now: see ROADMAP item 21.
    var SHOW_CATALOG = false;

    var root = null;
    var ui = {};
    var state = emptyState();
    var catalog = { categories: [], items: [] };
    var category = 'ALL';
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

    // Keeps digits and (when allowed) one decimal point.
    function cleanNumber(s, allowDecimal, maxLen) {
        var out = '';
        var dot = false;
        String(s || '').split('').forEach(function (c) {
            if (c >= '0' && c <= '9') { out += c; }
            else if (c === '.' && allowDecimal && !dot) { dot = true; out += (out === '' ? '0' : '') + '.'; }
        });
        return out.slice(0, maxLen || 12);
    }

    function send(name, payload) {
        // commands that change the lines move the highlight to the line AL reports
        followBackend = ['scan', 'addItem', 'recallDoc', 'deleteLine', 'newSale', 'hold', 'post'].indexOf(name) >= 0;
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

    // Focus goes back to the scan box after most taps so a USB/Bluetooth scanner always types there.
    // inputmode="none" keeps the on-screen keyboard closed for that automatic focus; tapping a box
    // itself switches it to the real keyboard.
    function focusInput(input) {
        if (overlay || !input) { return; }
        input.setAttribute('inputmode', 'none');
        try { input.focus({ preventScroll: true }); } catch (e) { input.focus(); }
    }

    function focusScan() { focusInput(ui.scan); }

    function keyboardOnTap(input, mode) {
        input.addEventListener('pointerdown', function () {
            if (input.getAttribute('inputmode') === 'none') {
                input.setAttribute('inputmode', mode);
                input.blur();
                setTimeout(function () { input.focus(); }, 0);
            }
        });
    }

    function findLine(lineNo) {
        for (var i = 0; i < state.lines.length; i++) {
            if (state.lines[i].lineNo === lineNo) { return state.lines[i]; }
        }
        return null;
    }

    function hasSale() { return !!state.docNo; }

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
        top.appendChild(ui.who);
        ui.clock = el('span', 'clock', '');
        top.appendChild(ui.clock);
        top.appendChild(btn('New sale', '', 'newSale'));
        top.appendChild(btn('Held sales', '', 'recall'));
        ui.shiftBtn = btn('Open shift', '', 'shift');
        top.appendChild(ui.shiftBtn);
        till.appendChild(top);

        var cols = el('div', 'cols' + (SHOW_CATALOG ? '' : ' two'));
        till.appendChild(cols);

        // ---- left: cart
        var left = el('div', 'col');
        ui.scan = el('input', 'scan');
        ui.scan.type = 'text';
        ui.scan.placeholder = 'Scan barcode, or type item name and press Enter';
        ui.scan.autocomplete = 'off';
        ui.scan.setAttribute('autocapitalize', 'off');
        ui.scan.setAttribute('inputmode', 'none');
        keyboardOnTap(ui.scan, 'text');
        ui.scan.addEventListener('keydown', function (e) {
            if (e.key === 'Enter') { e.preventDefault(); submitScan(); }
        });
        left.appendChild(ui.scan);

        ui.cart = el('div', 'box cart');
        left.appendChild(ui.cart);

        // loyalty member: one clear button, or the member card once added
        ui.loyBox = el('div', 'box member');
        left.appendChild(ui.loyBox);

        var totalBox = el('div', 'box totalbox');
        var tl = el('div', '');
        tl.appendChild(el('div', 'items', 'Total'));
        ui.items = el('div', 'items', '0 items');
        tl.appendChild(ui.items);
        totalBox.appendChild(tl);
        ui.total = el('div', 'big', '0.00');
        totalBox.appendChild(ui.total);
        left.appendChild(totalBox);

        ui.holdBtn = btn('Hold sale', 'hold', 'hold');
        totalBox.insertBefore(ui.holdBtn, totalBox.firstChild);
        cols.appendChild(left);

        // ---- middle: product buttons (hidden for now)
        if (SHOW_CATALOG) {
            var mid = el('div', 'col');
            ui.chips = el('div', 'chips');
            mid.appendChild(ui.chips);
            ui.grid = el('div', 'box grid');
            mid.appendChild(ui.grid);
            cols.appendChild(mid);
        }

        // ---- right: payment
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
        ui.paymentsRow = el('div', 'payments');
        ui.payments = el('span', '', '');
        ui.paymentsRow.appendChild(ui.payments);
        ui.clearPay = btn('Undo', 'undo', 'clearPayments');
        ui.paymentsRow.appendChild(ui.clearPay);
        stats.appendChild(ui.paymentsRow);
        right.appendChild(stats);

        // payment: each method opens its own dialog
        var pay = el('div', 'pay');
        ui.cashBtn = btn('Cash', 'primary', 'cash');
        pay.appendChild(ui.cashBtn);
        ui.mpesaBtn = btn('MPESA', 'primary', 'mpesa');
        pay.appendChild(ui.mpesaBtn);
        ui.cardBtn = btn('Card', 'primary', 'card');
        pay.appendChild(ui.cardBtn);
        right.appendChild(pay);
        right.appendChild(el('div', 'spacer'));
        ui.mpesaCheck = btn('Waiting for MPESA – check payment', 'mpesa-check', 'checkMpesa');
        right.appendChild(ui.mpesaCheck);
        ui.complete = btn('Complete sale', 'success complete', 'complete');
        right.appendChild(ui.complete);
        cols.appendChild(right);

        // events
        root.addEventListener('click', onClick);
        // keep the focus where it is: taps on buttons must not take it away
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
            ui.cart.appendChild(el('div', 'empty', 'Scan an item to start the sale'));
            return;
        }
        state.lines.forEach(function (l) {
            var row = el('div', 'line' + (l.lineNo === selected ? ' sel' : ''));
            row.setAttribute('data-act', 'line');
            row.setAttribute('data-line', l.lineNo);
            var info = el('div', 'info');
            info.appendChild(el('div', 'desc', l.description || l.itemNo));
            info.appendChild(el('div', 'price', money(l.unitPrice) + ' each'));
            row.appendChild(info);

            var ctl = el('div', 'ctl');
            ctl.appendChild(btn('−', 'step', 'minus', { line: l.lineNo }));
            var q = btn(qtyText(l.qty), 'qtyval', 'qtyEdit', { line: l.lineNo });
            q.title = 'Tap to type the quantity';
            ctl.appendChild(q);
            ctl.appendChild(btn('+', 'step', 'plus', { line: l.lineNo }));
            row.appendChild(ctl);

            row.appendChild(el('div', 'amt', money(l.amount)));
            row.appendChild(btn('✕', 'remove', 'void', { line: l.lineNo }));
            ui.cart.appendChild(row);
        });
        var selRow = ui.cart.querySelector('.line.sel');
        if (selRow && selRow.scrollIntoView) { selRow.scrollIntoView({ block: 'nearest' }); }
    }

    function renderTotals() {
        ui.total.textContent = money(state.amountDue);
        var n = state.itemCount || 0;
        ui.items.textContent = qtyText(n) + (n === 1 ? ' item' : ' items');
        ui.holdBtn.disabled = !state.lines.length;
    }

    function renderLoyalty() {
        var l = state.loyalty || {};
        ui.loyBox.innerHTML = '';
        ui.loyBox.style.display = l.enabled ? '' : 'none';
        if (!l.enabled) { return; }
        if (!l.phone) {
            ui.loyBox.className = 'box member none';
            ui.loyBox.appendChild(btn('★  Add loyalty member', 'addmember', 'member'));
            return;
        }
        ui.loyBox.className = 'box member on';
        var info = el('div', 'minfo');
        info.appendChild(el('div', 'mphone', '★ ' + l.phone));
        var t = l.balance + ' pts';
        if (l.pointsToEarn) { t += ' · earns ' + l.pointsToEarn; }
        if (l.pointsToRedeem) { t += ' · using ' + l.pointsToRedeem; }
        info.appendChild(el('div', 'mbal', t));
        ui.loyBox.appendChild(info);
        var r = btn(l.pointsToRedeem ? 'Change points' : 'Use points', '', 'redeem');
        r.disabled = !(l.maxRedeemable > 0) && !l.pointsToRedeem;
        ui.loyBox.appendChild(r);
        ui.loyBox.appendChild(btn('Remove', '', 'memberClear'));
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
        ui.paymentsRow.style.display = parts.length ? '' : 'none';
        ui.complete.disabled = !state.canComplete;
        ui.mpesaCheck.style.display = state.mpesaPending ? '' : 'none';
        var undoable = (state.payments || []).some(function (p) { return p.method !== 'MPESA'; });
        ui.clearPay.style.display = undoable ? '' : 'none';
        var canPay = state.stillToPay > 0;
        ui.cashBtn.disabled = !canPay;
        ui.mpesaBtn.disabled = !canPay;
        ui.cardBtn.disabled = !canPay;
    }

    function renderCatalog() {
        if (!SHOW_CATALOG || !ui.grid) { return; }
        ui.chips.innerHTML = '';
        var cats = (catalog.categories || []).slice();
        cats.sort(function (a, b) { return String(a.description).localeCompare(String(b.description)); });
        ui.chips.appendChild(btn('All', 'chip' + (category === 'ALL' ? ' on' : ''), 'cat', { code: 'ALL' }));
        cats.forEach(function (c) {
            var label = c.code === '' ? 'Other' : (c.description || c.code);
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
        a.appendChild(btn('Cancel', '', 'dlgCancel'));
        a.appendChild(btn(okLabel, 'danger', 'dlgOk'));
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

    // A dialog with its own number box and keypad. The box takes keyboard typing too.
    // opts: title, label, note, value, decimal (bool), maxLen, okLabel, okClass, validate(v) -> error text, onOk(v)
    function numberDialog(opts) {
        var d = el('div', 'dialog numdlg');
        d.appendChild(el('h2', '', opts.title));
        if (opts.note) { d.appendChild(el('div', 'note', opts.note)); }
        if (opts.label) { d.appendChild(el('label', 'dlglabel', opts.label)); }
        var input = el('input', 'dlginput');
        input.type = 'text';
        input.autocomplete = 'off';
        input.setAttribute('inputmode', 'none');
        input.value = opts.value === undefined || opts.value === null ? '' : String(opts.value);
        if (opts.placeholder) { input.placeholder = opts.placeholder; }
        if (!opts.decimal) { input.style.textAlign = 'left'; } // phone numbers and points read left to right
        d.appendChild(input);
        var live = el('div', 'dlglive', '');
        if (opts.live) { d.appendChild(live); }
        if (opts.quick && opts.quick.length) {
            var qrow = el('div', 'dlgquick');
            opts.quick.forEach(function (q) { qrow.appendChild(btn(q.label, '', 'dquick', { v: q.value })); });
            d.appendChild(qrow);
        }
        var err = el('div', 'dlgerr', '');
        d.appendChild(err);
        var fresh = input.value !== ''; // first key replaces a pre-filled value

        var pad = el('div', 'dlgpad');
        ['1', '2', '3', '4', '5', '6', '7', '8', '9', opts.decimal ? '.' : 'clear', '0', 'back'].forEach(function (k) {
            var label = k === 'back' ? '⌫' : (k === 'clear' ? 'C' : k);
            pad.appendChild(btn(label, '', 'dkey', { k: k }));
        });
        d.appendChild(pad);

        var a = el('div', 'actions');
        a.appendChild(btn('Cancel', '', 'dlgCancel'));
        a.appendChild(btn(opts.okLabel || 'OK', opts.okClass || 'primary', 'dlgOk'));
        d.appendChild(a);

        function setValue(v) {
            input.value = cleanNumber(v, opts.decimal, opts.maxLen);
            err.textContent = '';
            if (opts.live) { live.textContent = opts.live(input.value); }
        }

        function ok() {
            var v = input.value;
            var msg = opts.validate ? opts.validate(v) : '';
            if (msg) { err.textContent = msg; return; }
            closeOverlay();
            opts.onOk(v);
            focusScan();
        }

        input.addEventListener('input', function () { fresh = false; setValue(input.value); });
        input.addEventListener('keydown', function (e) {
            if (e.key === 'Enter') { e.preventDefault(); ok(); }
            else if (e.key === 'Escape') { e.preventDefault(); closeOverlay(); focusScan(); }
        });
        keyboardOnTap(input, opts.decimal ? 'decimal' : 'numeric');

        d.addEventListener('click', function (e) {
            var b = e.target.closest ? e.target.closest('button') : null;
            if (!b) { return; }
            e.stopPropagation();
            var act = b.getAttribute('data-act');
            if (act === 'dquick') { setValue(b.getAttribute('data-v')); fresh = true; }
            else if (act === 'dkey') {
                var k = b.getAttribute('data-k');
                if (k === 'back') { setValue(fresh ? '' : input.value.slice(0, -1)); }
                else if (k === 'clear') { setValue(''); }
                else { setValue((fresh ? '' : input.value) + k); }
                fresh = false;
            } else if (act === 'dlgOk') { ok(); }
            else { closeOverlay(); focusScan(); }
        });

        if (opts.live) { live.textContent = opts.live(input.value); }
        openOverlay(d);
        input.setAttribute('inputmode', 'none');
        try { input.focus({ preventScroll: true }); } catch (e2) { input.focus(); }
        input.select();
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
            left.appendChild(el('span', 'sub', it.subtitle || ''));
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

    // A barcode typed into a number box by the scanner: treat it as a scan, not as an amount.
    function looksLikeBarcode(v) { return /^\d{8,}$/.test(v); }

    function openCash() {
        if (!hasSale() || !(state.stillToPay > 0)) { toast('Nothing left to pay.', true); return; }
        var due = state.stillToPay;
        var quick = [{ label: 'Exact ' + money(due), value: '' }];
        [50, 100, 200, 500, 1000, 2000].forEach(function (n) {
            if (n > due && quick.length < 5) { quick.push({ label: money(n).replace('.00', ''), value: String(n) }); }
        });
        numberDialog({
            title: 'Cash',
            note: 'To pay: ' + money(due),
            label: 'Cash received',
            placeholder: 'Exact amount',
            value: '',
            decimal: true,
            quick: quick,
            okLabel: 'Take cash',
            okClass: 'success',
            live: function (v) {
                var n = v === '' ? due : num(v);
                if (n > due) { return 'Change: ' + money(n - due); }
                if (n < due) { return 'Still to pay after this: ' + money(due - n); }
                return 'No change';
            },
            validate: function (v) {
                if (looksLikeBarcode(v)) { return 'That looks like a barcode. Close this and scan the item.'; }
                if (num(v) - due > 10000) { return 'That would be more than 10,000 change. Check the amount.'; }
                return '';
            },
            onOk: function (v) { send('payCash', { amount: num(v) }); } // empty = exact cash
        });
    }

    function phoneValid(v) {
        return v.length >= 9 ? '' : 'Enter the full phone number, for example 0712345678.';
    }

    function openMpesa() {
        if (!hasSale() || !(state.stillToPay > 0)) { toast('Nothing left to pay.', true); return; }
        numberDialog({
            title: 'Pay with MPESA',
            note: 'The customer gets a prompt on their phone to pay KES ' + money(Math.ceil(state.stillToPay)) +
                '. They enter their MPESA PIN, then you tap "Check payment".',
            label: 'Customer phone number',
            value: (state.loyalty && state.loyalty.phone) || state.mpesaPhone || '',
            decimal: false,
            maxLen: 13,
            okLabel: 'Send payment request',
            validate: phoneValid,
            onOk: function (v) { send('payMpesa', { phone: v }); }
        });
    }

    function openCard() {
        if (!hasSale() || !(state.stillToPay > 0)) { toast('Nothing left to pay.', true); return; }
        numberDialog({
            title: 'Pay by card',
            note: 'Charge the card on the terminal, then confirm the amount here.',
            label: 'Amount charged',
            value: String(Math.round(state.stillToPay * 100) / 100),
            decimal: true,
            okLabel: 'Card paid',
            validate: function (v) {
                var n = num(v);
                if (n <= 0) { return 'Enter the amount.'; }
                if (n > state.stillToPay + 0.001) { return 'A card cannot pay more than ' + money(state.stillToPay) + '.'; }
                return '';
            },
            onOk: function (v) { send('payCard', { amount: num(v), reference: '' }); }
        });
    }

    function openQty(lineNo) {
        var l = findLine(lineNo);
        if (!l) { return; }
        numberDialog({
            title: 'Quantity',
            note: l.description || l.itemNo,
            value: qtyText(l.qty),
            decimal: true,
            maxLen: 9,
            okLabel: 'Set quantity',
            validate: function (v) { return num(v) > 0 ? '' : 'Enter a quantity above 0. To remove the item, use ✕.'; },
            onOk: function (v) { send('setQty', { lineNo: lineNo, qty: num(v) }); }
        });
    }

    function confirmRemove(lineNo) {
        var l = findLine(lineNo);
        if (!l) { return; }
        confirmDialog('Remove item', 'Remove ' + qtyText(l.qty) + ' × ' + (l.description || l.itemNo) + ' from the sale?', 'Remove', function () {
            send('deleteLine', { lineNo: lineNo });
        });
    }

    function openMember() {
        numberDialog({
            title: 'Loyalty member',
            note: 'Enter the customer\'s phone number. A new number can be registered as a member.',
            label: 'Phone number',
            value: '',
            decimal: false,
            maxLen: 13,
            okLabel: 'Add member',
            validate: phoneValid,
            onOk: function (v) { send('loyaltyPhone', { phone: v }); }
        });
    }

    function openRedeem() {
        var l = state.loyalty || {};
        var max = l.maxRedeemable || 0;
        numberDialog({
            title: 'Use loyalty points',
            note: l.phone + ' has ' + l.balance + ' points. Up to ' + max + ' can be used on this sale' +
                (l.pointValue ? ' (1 point = KES ' + money(l.pointValue) + ').' : '.') + ' Enter 0 to use none.',
            label: 'Points to use',
            value: String(l.pointsToRedeem || max),
            decimal: false,
            maxLen: 7,
            okLabel: 'Use points',
            validate: function (v) { return num(v) > max ? 'At most ' + max + ' points.' : ''; },
            onOk: function (v) { send('redeem', { points: Math.floor(num(v)) }); }
        });
    }

    function onClick(e) {
        var t = e.target.closest ? e.target.closest('[data-act]') : null;
        if (!t || t.disabled) { return; }
        if (overlay && overlay.contains(t)) { return; } // dialogs handle their own buttons
        var act = t.getAttribute('data-act');
        var lineNo = Number(t.getAttribute('data-line')) || 0;
        var l;

        switch (act) {
            case 'note': send('payCash', { amount: Number(t.getAttribute('data-amt')) }); break;
            case 'cash': openCash(); return;
            case 'card': openCard(); return;
            case 'mpesa': openMpesa(); return;
            case 'checkMpesa': send('checkMpesa', {}); break;
            case 'clearPayments': send('clearPayments', {}); break;
            case 'complete': send('post', {}); break;
            case 'tile': send('addItem', { itemNo: t.getAttribute('data-no'), qty: 1 }); break;
            case 'cat': category = t.getAttribute('data-code'); renderCatalog(); break;
            case 'line': selected = lineNo; renderCart(); break;
            case 'plus':
                l = findLine(lineNo);
                if (l) { selected = lineNo; send('setQty', { lineNo: lineNo, qty: Number(l.qty) + 1 }); }
                break;
            case 'minus':
                l = findLine(lineNo);
                if (!l) { break; }
                selected = lineNo;
                if (Number(l.qty) > 1) { send('setQty', { lineNo: lineNo, qty: Number(l.qty) - 1 }); }
                else { confirmRemove(lineNo); return; }
                break;
            case 'qtyEdit': selected = lineNo; openQty(lineNo); return;
            case 'void': confirmRemove(lineNo); return;
            case 'hold': send('hold', {}); break;
            case 'recall': send('recall', {}); break;
            case 'newSale': send('newSale', {}); break;
            case 'shift': send(state.shiftNo ? 'closeShift' : 'openShift', {}); break;
            case 'member': openMember(); return;
            case 'memberClear': send('loyaltyPhone', { phone: '' }); break;
            case 'redeem': openRedeem(); return;
            default: return;
        }
        focusScan();
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
        if (!state.docNo) { selected = 0; }
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
