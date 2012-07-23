require 'psych'
require 'pivotal-tracker'

class TrackerReports
  class << self
    def config
      return @config if @config
      config_filename = File.join(ENV['HOME'], ".tracker.yml")
      raise "No tracker.yml: '#{config_filename}" unless File.exists?(config_filename)
      File.open(config_filename) do |f|
        @config = Psych.load(f)
      end
      @config
    end
  end

  attr_reader :options

  def initialize(options)
    @options = options
    PivotalTracker::Client.token = self.class.config["api_token"]
  end

  def project
    @project ||= PivotalTracker::Project.find(options[:project_id])
  end

  def accepted_stories
    @accepted_stories ||= project.stories.all.select do|s| 
      s.accepted_at && s.accepted_at >= options[:start_date] && s.accepted_at <= options[:end_date]
    end.sort_by(&:accepted_at)
  end

  def accepted_summary
    accepted_stories.collect { |s| story_to_s(s) }.join("\n")
  end

  def finished_summary
    finished_stories.collect { |s| story_to_s(s) }.join("\n")
  end

  def finished_stories
    @finished_stories ||= project.stories.all.select do |s|
      s.current_state == "finished" && s.current_state = "delivered"
    end
  end

  def accepted_points
    accepted_stories.inject(0) { |sum, story| sum + story.estimate.to_i }
  end

  def finished_points
    finished_stories.inject(0) { |sum, story| sum + story.estimate.to_i }
  end


  def story_summary
    <<-EOR
# Accepted stories between #{options[:start_date]} and #{options[:end_date]}
#{accepted_summary}

Total stories: #{accepted_stories.size}, Total points: #{accepted_points}

# Finished and Delivered stories
#{finished_summary}
Total stories: #{finished_stories.size}, Total points: #{finished_points}

EOR
  end

  def story_to_s(s)
    string = "* #{s.id} (#{s.story_type[0].upcase}"
    if s.story_type == "feature"
      string += "/#{s.estimate}"
    end
    string += "): #{s.name} "
    if s.accepted_at
      string += "#{s.accepted_at.strftime('%F')}"
    end
    string
  end
end