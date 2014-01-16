
class Ec2::Blackout::Options

  DEFAULT_REGIONS = ['us-east-1', 'us-west-1', 'us-west-2', 'eu-west-1', 'ap-southeast-1', 'ap-southeast-2', 'ap-northeast-1', 'sa-east-1']

  def initialize(options = {})
    @options = options
    @options[:regions] = DEFAULT_REGIONS unless @options[:regions]
  end

  def include_tags
    @include_tags ||= key_value_hash(@options[:include_by_tag])
  end

  def exclude_tags
    @exclude_tags ||= key_value_hash(@options[:exclude_by_tag])
  end

  def matches_include_tags?(tags)
    return true unless include_tags
    matches_tags?(include_tags, tags)
  end

  def matches_exclude_tags?(tags)
    return false unless exclude_tags
    matches_tags?(exclude_tags, tags)
  end

  def regions
    @options[:regions]
  end

  def dry_run
    @options[:dry_run]
  end

  def force
    @options[:force]
  end


  private

  def matches_tags?(tags_to_match, tags)
    tags_to_match.each do |tag_name, tag_value|
      return false unless tags[tag_name] =~ /#{tag_value}/
    end
    true
  end

  def key_value_hash(options)
    options ? Hash[options.map { |opt| opt.split("=", 2).map(&:strip) }] : nil
  end

end
