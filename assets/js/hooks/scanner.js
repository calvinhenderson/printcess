export const ScannerHook = {
  time() {
    return new Date().getTime();
  },

  mounted() {
    this.input = this.el;
    this.el.addEventListener("keydown", (ev) => this.keydown(ev));
    this.el.addEventListener("submit", () => this.submitted());

    this.barcodeChars = [];
    this.scannerThresholdMs = this.el.getAttribute('data-threshold-ms') || 20;
    this.minBarcodeLength = this.el.getAttribute('data-barcode-min-length') || 4;
  },

  submitted() {
    this.input.focus();
  },

  keydown(event) {
    if (!this.lastInputTime) this.lastInputTime = this.time();
    const currentTime = this.time();
    const delta = currentTime - this.lastInputTime;

    if (delta < this.scannerThresholdMs) {
      this.barcodeChars.push(event.key);
    } else {
      this.barcodeChars = [event.key];
    }

    this.lastInputTime = currentTime;

    if (event.key === "Enter") {
      if (this.barcodeChars.length >= this.minBarcodeLength) {
        console.log('Scanner detected. Barcode: ', this.barcodeChars.join(''));
        event.preventDefault();
        this.barcodeChars = [];
      }
    }
  }
};


