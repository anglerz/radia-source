class Program < ActiveRecord::Base
  extend RadiaSource::TimeUtils
  
  acts_as_urlnameable :name, :overwrite => true
  #acts_as_emission_process_configurable :recorded => true
  acts_as_authorizable
  
  validates_uniqueness_of :name, :on => :save, :message => "must be unique"
    
  has_many :broadcasts, :dependent => :destroy, :order => 'dtstart ASC'
  
  has_many :emissions
  has_many :repetitions
  
  # Shorthand to retrieve upcoming emissions (FIRST-TIME broadcasts, not repetitions)
  has_many :upcoming_emissions, :class_name => "Emission", 
                                :conditions => ["dtstart >= ?", Time.now], 
                                :order => 'dtstart ASC', 
                                :limit => 5
  has_many :authorships, :dependent => :destroy
  has_many :authors, :through => :authorships, :class_name => 'User', :source => :user
  
  # Generate URLs based on the program's urlname
  def to_param
    self.urlname
  end

  # Tests if the program has an emission on a given date (includes repetitions)
  def has_emissions?(date)
    !self.find_emission_by_date(date.year, date.month, date.day).blank?
  end

  # Find all broadcasts on a given date (includes repetitions)
  def find_broadcasts_by_date(year, month = nil, day = nil)
    find_broadcasts_by_date_on_collection(broadcasts, year, month, day)
  end

  # Find all broadcasts on a given date (does not include repetitions)
  def find_emissions_by_date(year, month = nil, day = nil)
    find_broadcasts_by_date_on_collection(emissions, year, month, day)
  end

  # Find one broadcast on a given date (emissions + repetitions)
  def find_emission_by_date(year, month, day)
    self.find_emissions_by_date(year, month, day).first
  end
  
  # Finds the closest emission (not repetition) that starts before the given date
  def find_first_emission_before_date(date)
    self.emissions.find(:first, :order => 'dtstart DESC', :conditions => ["dtstart <= ?", date])
  end
  
  def parent
    ProgramSchedule.instance
  end
  
  def to_xml(options = {})
    options[:indent] ||= 2
    options[:replace_unavailable] ||= false
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml.program do 
      xml.tag!(:id, self.urlname, :type => :string)
      xml.tag!(:description, self.description, :type => :string)
    end
  end
  
  protected
  
  def find_broadcasts_by_date_on_collection(kollection, year, month = nil, day = nil)
    if !year.blank?
      from, to = self.class.time_delta(year, month, day)
      kollection.find(:all, :conditions => ["dtstart BETWEEN ? AND ?", from, to])
    else
      kollection.find(:all)
    end
  end
end
