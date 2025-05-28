export const AutoFocusHook = {
  mounted() {
    // element was added to DOM
    let inputs = this.el.querySelectorAll('input:not(:disabled)')

    this.input = this.el;
    if (inputs.length > 0) this.input = inputs[0];

    this.el.addEventListener("submit", () => this.submitted());
  },

  submitted() {
    this.input.focus();
  },
};

