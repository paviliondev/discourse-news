import Controller from "@ember/controller";
import NewsAdmin from '../models/news-admin';

export default Controller.extend({
  message: null,
  
  actions: {
    updateExcerpts() {
      this.set('loading', true);
      
      NewsAdmin.updateExcerpts().then(result => {
        if (result.success) {
          this.set('message', I18n.t('news.excerpt.updating'))
        } else {
          this.set('message', I18n.t('news.excerpt.update_failed'))
        }
      }).finally(() => {
        this.set('loading', false)
        setTimeout(() => {
          this.set('message', null);
        }, 10000);
      });
    }
  }
})