require 'psych'
require 'pivotal-tracker'

class TrackerReports
  class << self
    def config
      return @config if @config
      config_filename = File.join(ENV['HOME'], ".tracker.yml")
      raise "No tracker.yml: '#{config_filename}" unless File.exists?(config_filename)
      File.open(config_filename) do |f|
        yaml = f.read
        @config = Psych.load(yaml)
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

  def finished_stories
    @finished_stories ||= project.stories.all.select do |s|
      s.current_state == "finished" && s.current_state = "delivered"
    end
  end

  def accepted_summary
    accepted_stories.collect { |s| story_to_s(s) }.join("\n")
  end

  def finished_summary
    finished_stories.collect { |s| story_to_s(s) }.join("\n")
  end

  def accepted_points
    accepted_stories.inject(0) { |sum, story| sum + story.estimate.to_i }
  end

  def finished_points
    finished_stories.inject(0) { |sum, story| sum + story.estimate.to_i }
  end


  def accepted_story_summary
    return "" unless accepted_stories.size > 0
    <<-EOR
# Accepted stories between #{options[:start_date]} and #{options[:end_date]}
#{accepted_summary}

Total stories: #{accepted_stories.size}
Total Bugs: #{bug_count(accepted_stories)}
Total Chores: #{chore_count(accepted_stories) }
Total feature points: #{accepted_points}
EOR
  end

  def bug_count(story_list)
    story_list.select { |s| s.story_type == 'bug' }.count     
  end

  def chore_count(story_list)
    story_list.select { |s| s.story_type == 'chores' }.count    
  end
  
  def finished_story_summary
    return "" unless finished_stories.size > 0
    <<-EOR
# Finished and Delivered stories
#{finished_summary}
Total stories: #{finished_stories.size}, Total points: #{finished_points}

EOR
  end
  
  def story_summary
    accepted_story_summary + finished_story_summary
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
