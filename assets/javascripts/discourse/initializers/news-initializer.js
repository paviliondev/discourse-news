import { withPluginApi } from "discourse/lib/plugin-api";
import NewsHeaderButton from "../components/news-header-button";

export default {
  name: "news-edits",
  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");

    if (!siteSettings.discourse_news_enabled) {
      return;
    }

    withPluginApi("1.6.0", (api) => {
      api.headerButtons.add("news", NewsHeaderButton, { before: "auth" });

      api.modifyClass(
        "model:topic",
        (Superclass) =>
          class extends Superclass {
            get basicCategoryLinkHtml() {
              const category = this.category;
              if (!category) {
                return "";
              }
              return `<a class="basic-category-link" href="${category.url}" title="${category.name}">${category.name}</a>`;
            }
          }
      );
    });
  },
};
