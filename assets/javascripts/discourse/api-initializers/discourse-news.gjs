import { apiInitializer } from "discourse/lib/api";
import NewsHeaderButton from "../components/news-header-button";

export default apiInitializer("1.0", (api) => {
  const siteSettings = api.container.lookup("service:site-settings");
  if (!siteSettings.discourse_news_enabled) {
    return;
  }

  api.headerIcons.add("news", NewsHeaderButton, { before: "search" });

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
