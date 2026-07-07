require "yaml"

class OkfConcept
  FRONTMATTER = /\A---\s*\n(.*?)\n---\s*\n/m

  attr_reader :path, :metadata, :body

  def self.load_all(root: Rails.root.join("knowledge"))
    root = Pathname(root)
    root.glob("**/*.md").sort.map { |file| parse(file, root:) }
  end

  def self.parse(file, root: Rails.root.join("knowledge"))
    raw = File.read(file)
    match = raw.match(FRONTMATTER)
    raise ArgumentError, "Missing YAML frontmatter in #{file}" unless match

    metadata = YAML.safe_load(match[1], permitted_classes: [ Date, Time ], aliases: false) || {}
    raise ArgumentError, "Missing required OKF type in #{file}" if metadata["type"].blank?

    new(
      path: Pathname(file).relative_path_from(Pathname(root)).to_s,
      metadata: metadata,
      body: raw.sub(FRONTMATTER, "").strip
    )
  end

  def self.find_by_tag(tag, concepts: load_all)
    tag = tag.to_s.downcase
    concepts.select { |concept| concept.tags.include?(tag) }
  end

  def self.find_by_type(type, concepts: load_all)
    type = type.to_s.downcase
    concepts.select { |concept| concept.type == type }
  end

  def self.map(concepts: load_all)
    concepts.map(&:to_map)
  end

  def initialize(path:, metadata:, body:)
    @path = path
    @metadata = metadata
    @body = body
  end

  def type = metadata.fetch("type").to_s.downcase
  def title = metadata["title"].presence || path
  def description = metadata["description"].to_s
  def resource = metadata["resource"].presence || "knowledge/#{path}"
  def timestamp = metadata["timestamp"].to_s

  def tags
    Array(metadata["tags"]).map { |tag| tag.to_s.downcase }
  end

  def to_map
    {
      path: path,
      type: type,
      title: title,
      tags: tags
    }
  end
end
