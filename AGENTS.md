# 博客发布规则

- 常规文章放在 `content/posts/`，并使用标题、日期、描述、标签和 `draft: false` 的 Frontmatter。
- 普通文章的尾部引用声明由 `layouts/partials/article-citation.html` 自动生成；不要在 Markdown 正文中手写或重复添加引用区块。
- `layouts/_default/single.html` 只会为位于 `posts` 且 `type` 不为 `page` 的内容渲染该声明，因此 Welcome、Projects、Contact 等 `type: "page"` 页面不受影响。
- 文章正文不要重复 Frontmatter 已渲染的 H1 标题。
