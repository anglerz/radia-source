class Program < ActiveRecord::Base
  include TimeUtils
  
  acts_as_authorizable
  acts_as_urlnameable :name, :overwrite => true
  acts_as_emission_process_configurable :recorded => true
  
  validates_uniqueness_of :name, :on => :save, :message => "must be unique"
    
  has_many :emissions, :dependent => :destroy, 
                        :conditions => ["active = ?", true], :order => 'start ASC'
                        
  has_many :inactive_emissions, :class_name => "Emission", :dependent => :destroy, 
                                :conditions => ["active = ?", false], :order => 'start ASC'
  
  # Shorthand to retrieve upcoming emissions
  has_many :upcoming_emissions, :class_name => "Emission", 
                                :conditions => ["start >= ? AND type <> 'RepeatedEmission'", Time.now], 
                                :order => 'start ASC', 
                                :limit => 5
  has_many :authorships, :dependent => :destroy
  has_many :authors, :through => :authorships
  
  # Generate URLs based on the program's urlname
  def to_param
    self.urlname
  end

  # Tests if the program has an emission on a given date
  def has_emissions?(date)
    !self.find_emission_by_date(date.year, date.month, date.day).blank?
  end

  # Find all emissions on a given date
  def find_emissions_by_date(year, month = nil, day = nil)
    if !year.blank?
      from, to = TimeUtils.time_delta(year, month, day)
      emissions.find(:all, :conditions => ["start BETWEEN ? AND ?", from, to])
    else
      emissions.find(:all)
    end
  end

  # Find one emission on a given date
  def find_emission_by_date(year, month, day)
    self.find_emissions_by_date(year, month, day).first
  end
  
  # Finds the closest emission that starts before the given date
  def find_first_emission_before_date(date)
    self.emissions.find(:first, :order => 'start DESC',
                        :conditions => ["type <> 'RepeatedEmission' AND start <= ?", date])
  end
  
  def parent
    ProgramSchedule.instance
  end
end
