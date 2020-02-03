import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';
import EmberObject from "@ember/object";

const NewsAdmin = EmberObject.extend();

NewsAdmin.reopenClass({
  updateExcerpts() {
    return ajax('/admin/plugins/news/excerpts', {
      type: "POST"
    }).catch(popupAjaxError);
  }
});

export default NewsAdmin;

