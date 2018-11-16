export default {
  setupComponent(attrs, component) {
    const currentRoute = this.get('parentView.parentView.currentRoute');
    component.set('includeSharePopup', currentRoute == 'news');
  }
}
