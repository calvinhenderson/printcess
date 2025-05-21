function getByAttribute(element, attr) {
  return document.getElementById(element.getAttribute('data-' + attr));
}

export const AutoFocusHook = {
  mounted() {
    // element was added to DOM
    this.input = getByAttribute(this.el, 'focus-input');
    this.el.addEventListener("submit", () => this.submitted());
  },

  submitted() {
    this.input.focus();
  },
};

