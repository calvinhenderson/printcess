function getByAttribute(element, attr) {
  return document.getElementById(element.getAttribute('data-' + attr));
}

export const AutoCompleteHook = {
  mounted() {
    // element was added to DOM
    console.log("connected timestamp hook");
    this.template = getByAttribute(this.el, 'template');
    this.container = getByAttribute(this.el, 'container');
  },

  updated() {
    // element was updated, rerender
    this.push_event("suggest", {type: this.el.getAttribute('data-type'), query: this.el.value});
    this.render();
  },

  render() {
    console.log("Rendering suggestions..");
    // Clear the existing suggestions
    this.container.replaceChildren();

    // Make sure we have valid data
    let suggestions = this.el.getAttribute('data-suggestions');
    if (! (Array.isArray(suggestions)
      && suggestions.length > 0
      && typeof suggestions[0] == 'object')) return;

    // Render new suggestions
    for (suggestion in suggestions) {
      let el = this.template.content.cloneNode(true);

      // update the template params
      for (const [key, value] of suggestion) {
        el.outerHtml.replaceAll("{{\\s*${key}\\s*}}", value);
      }

      // add the entry to the list
      this.container.appendChild(el);
    }
  }
};
