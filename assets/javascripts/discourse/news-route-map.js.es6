export default {
  resource: 'discovery',
  map() {
    this.route('news', { path: '/news', resetNamespace: true });
  }
};
