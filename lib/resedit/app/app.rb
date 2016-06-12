require 'resedit/app/std_commands'
require 'logger'

module Resedit
    
    class App
        attr_reader :name, :version, :commands, :logger, :copyright, :cmdInterface

        def self.get()
            return @@instance
        end

        def initialize(name, version, commands, cmdInterface=true, copyright="(c) old-games.ru")
            @@instance = self
            @name, @version, @copyright = name, version, copyright
            @cmdInterface = cmdInterface
            @logger = Logger.new(STDOUT)
            @logger.level= Logger::INFO
            logger.formatter = proc { |severity, datetime, progname, msg|
                severity+": "+msg
            }
            @commands = commands
            @commands+=[HelpCommand.new(), VersionCommand.new(), ExitCommand.new(), EchoCommand.new(), ScriptCommand.new()]
            @cmds={}
            @commands.each{|c|
                c.names.each{|n|
                    @cmds[n] = c;
                }
            }
        end


        def logd(fmt, *args)
            @logger.debug(sprintf(fmt+"\n",*args))
        end
        def log(fmt, *args)
            @logger.info(sprintf(fmt+"\n",*args))
        end
        def loge(fmt, *args)
            @logger.error(sprintf(fmt+"\n",*args))
        end


        def quit
            @stop=true
        end

        def parseCommand(string)
            cmd = []
            string.split().each {|w|
                if w[0]=='-' && w.length()>2 && w[1]!='-'
                    w[1..-1].each_char{|c|
                        cmd+=['-#{c}']
                    }
                else
                    cmd+=[w]
                end
            }
            logd("parsing command #{cmd.to_s}")
            c = @cmds[cmd[0]]
            raise "Unknown command: #{cmd[0]}" if !c
            res=[]
            prms = c.parseParams(cmd[1..-1])
            return c,prms
        end


        def runCommand(string)
            logd("running command %s", string)
            cmd = parseCommand(string)
            cmd[0].run(cmd[1])
        end


        def commandInterface()
            runCommand('version')
            @stop=false
            while(!@stop)
                print "#{@name}> "
                begin
                    runCommand(gets.chomp())
                rescue StandardError => e
                    puts "Error: #{e.to_s()}"
                    puts e.backtrace
                end
            end
            return 0
        end


        def run()
            begin
                if ARGV.length()==0
                    commandInterface() if @cmdInterface
                    runCommand('help') if !@cmdInterface
                else
                    if (@cmds[ARGV[0]])
                        #check command
                        runCommand(ARGV.join(' '))
                    elsif ARGV.length()==1 && File.exists?(ARGV[0])
                        #check script
                        runCommand('script '+ARGV[0])
                    else
                        raise "unknown command #{ARGV[0]}"
                    end
                end
                exit(0)
            rescue StandardError => e
                puts "Error: #{e.to_s()}"
                puts e.backtrace
                exit(1)
            end
        end

    end

end