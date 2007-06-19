# ant_project.rb
#
# Copyright Caleb Powell 2007
#
# Licensed under the LGPL, see the file COPYING in the distribution
#

class AntProject 
  require 'logger'
  require 'ant_task'
  
  private
  @@classes_loaded = false
  
  def init_project(options)
  
    @project= ApacheAnt::Project.new
    @project.setName(options[:name] || '')
    @project.setDefault('')
    @project.setBasedir(options[:basedir] || FileUtils::pwd)
    @project.init
    if options[:declarative] == nil
      @logger.debug("declarative is nil")
      self.declarative= true
    else
      @logger.debug("declarative is #{options[:declarative]}")
      self.declarative= options[:declarative]
    end      
    default_logger = ApacheAnt::DefaultLogger.new
    default_logger.setMessageOutputLevel(2)
    default_logger.setOutputPrintStream(options[:outputstr] || JavaLang::System.out)
    default_logger.setErrorPrintStream(options[:errorstr] || JavaLang::System.err)
    default_logger.setEmacsMode(false)
    @project.addBuildListener(default_logger)
    
  end
  
  public
  attr :project, false
  attr :ant_version, false
  attr_accessor(:declarative, :logger)
  
  # Create an AntProject. Parameters are specified via a hash:
  # :ant_home=><em>Ant basedir</em>
  #   -A String indicating the location of the ANT_HOME directory. If provided, Antwrap will
  #   load the classes from the ANT_HOME/lib dir. If ant_home is not provided, the Ant jar files
  #   must be available in the CLASSPATH.   
  # :name=><em>project_name</em>
  #   -A String indicating the name of this project.
  # :basedir=><em>project_basedir</em>
  #   -A String indicating the basedir of this project. Corresponds to the 'basedir' attribute 
  #   on an Ant project.  
  # :declarative=><em>declarative_mode</em>
  #   -A boolean value indicating wether Ant tasks created by this project instance should 
  #   have their execute() method invoked during their creation. For example, with 
  #   the option :declarative=>true the following task would execute; 
  #   @antProject.echo(:message => "An Echo Task")
  #   However, with the option :declarative=>false, the programmer is required to execute the 
  #   task explicitly; 
  #   echoTask = @antProject.echo(:message => "An Echo Task")
  #   echoTask.execute()
  #   Default value is <em>true</em>.
  # :logger=><em>Logger</em>
  #   -A Logger instance. Defaults to Logger.new(STDOUT)
  # :loglevel=><em>The level to set the logger to</em>
  #   -Defaults to Logger::ERROR
  def initialize(options=Hash.new)
    
    @logger = options[:logger] || Logger.new(STDOUT)
    @logger.level = options[:loglevel] || Logger::ERROR
    
    if(!@@classes_loaded && options[:ant_home])
      @logger.debug("loading ant jar files. Ant_Home: #{options[:ant_home]}")
      AntwrapClassLoader.load_ant_libs(options[:ant_home])
      @@classes_loaded = true
    end
    
    @logger.debug(ApacheAnt::Main.getAntVersion())
    @ant_version = ApacheAnt::Main.getAntVersion()[/\d\.\d\.\d/].to_f
    init_project(options)
    
    @task_stack = Array.new
    
  end
  
  def method_missing(sym, *args)
    
    begin
      task = AntTask.new(sym.to_s, self, args[0])
      
      parent_task = @task_stack.last
      @task_stack << task
      
      yield self if block_given?
      
      parent_task.add(task) if parent_task
      
      if @task_stack.nitems == 1 
        if declarative == true
          @logger.debug("Executing #{task}")
          task.execute 
        else 
          @logger.debug("Returning #{task}")
          return task
        end  
      end
    
    rescue
      @logger.error("Error instantiating '#{sym.to_s}' task: " + $!)
      raise
    ensure
      @task_stack.pop
    end
    
  end
  
  #The Ant Project's name. Default is ''
  def name
    return @project.getName
  end
  
  #The Ant Project's basedir. Default is '.'
  def basedir
    return @project.getBaseDir().getAbsolutePath();
  end
  
  #Displays the Class name followed by the AntProject name
  # -e.g.  AntProject[BigCoProject]
  def to_s
    return self.class.name + "[#{name}]"
  end 
  
end