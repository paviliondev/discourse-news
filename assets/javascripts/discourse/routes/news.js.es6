import buildTopicRoute from "discourse/routes/build-topic-route";

export default buildTopicRoute('news', {
  renderTemplate() {
    this.render("discovery/topics", {
      controller: "discovery/topics",
      outlet: "list-container"
    });
  }
});
