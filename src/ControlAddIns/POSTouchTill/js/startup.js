// Startup: build the till, then tell AL it can send data (catalog and sale state).
(function () {
    var root = document.getElementById('controlAddIn');
    if (!root) {
        root = document.body;
    }
    PosTill.init(root);
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ControlReady', []);
})();
