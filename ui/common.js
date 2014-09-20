window.util = {
	dispatchMessage: function(m) {
		var k, handler;
		for (k in m) {
			if ((handler = this["msg_" + k])) {
				handler.call(this, m[k]);
			} else {
				throw new Error("Unknown key in message: " + k);
			}
		}
	}
};
