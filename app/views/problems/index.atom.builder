atom_feed do |feed|
  feed.title(@title)

  feed.updated(@updated)

  @stories.each do |story|
    feed.entry(story) do |entry|
      entry.title(h(story.subject))
      entry.summary(truncate(strip_tags(story.description), :length => 100))
      entry.author do |author|
        author.name(story.reporter.name.blank? ? t(:anonymous) : story.reporter.name)
      end
    end
  end
end