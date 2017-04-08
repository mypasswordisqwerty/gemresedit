require 'resedit/app/std_commands'
require 'resedit/app/mz_command'
require 'resedit/app/colorizer'
require 'logger'
require 'readline'

module Resedit

    class App
        HIST_FILE = "~/.resedithist"
        attr_reader :name, :version, :commands, :logger, :copyright, :cmdInterface, :shell, :col

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
                msg
            }
            @shell = nil;
            @commands = []
            @commands += commands if commands
            @commands += [HelpCommand.new(), VersionCommand.new(), ExitCommand.new(),
                        ScriptCommand.new(), MZCommand.new(), ShellCommand.new()]
            @cmds={}
            @commands.each{|c|
                c.names.each{|n|
                    @cmds[n] = c;
                }
            }
            @col = Colorizer.new(false)
        end


        def logd(fmt, *args)
            @logger.debug(@col.gray(sprintf(fmt+"\n",*args)))
        end
        def log(fmt, *args)
            @logger.info(sprintf(fmt+"\n",*args))
        end
        def loge(fmt, *args)
            @logger.error(@col.red(sprintf(fmt+"\n",*args)))
        end


        def quit
            begin
                strt = Readline::HISTORY.length-64
                open(File.expand_path(HIST_FILE),"w"){|f|
                    Readline::HISTORY.each.with_index{|ln,i|
                        f.write(ln+"\n") if i > strt
                    }
                }
            rescue
            end
            @stop=true
        end

        def setShell(sname)
            sname=nil if sname.length==0
            raise "Unknown shell: "+sname if sname && !@cmds[sname]
            @shell = sname
        end

        def parseCommand(string)
            cmd = []
            string.split().each {|w|
                if w[0]=='-' && w.length()>2 && w[1]!='-'
                    w[1..-1].each_char{|c|
                        cmd+=["-#{c}"]
                    }
                else
                    cmd+=[w]
                end
            }
            logd("parsing command #{cmd.to_s}")
            return nil if cmd.length()==0 || cmd[0][0]=='#'
            c = @cmds[cmd[0]]
            raise "Unknown command: #{cmd[0]}" if !c
            res=[]
            prms = c.parseParams(cmd[1..-1])
            return c,prms
        end


        def runCommand(string)
            if @shell
                cmd=string.split()[0]
                if !@cmds[cmd] || !['Resedit::ExitCommand','Resedit::ShellCommand'].include?(@cmds[cmd].class.name)
                    string = @shell+" "+string
                end
            end
            logd("running command %s", string)
            cmd = parseCommand(string)
            cmd[0].run(cmd[1])
        end


        def commandInterface()
            @cmds['version'].run('')
            begin
                open(File.expand_path(HIST_FILE),"r").each_line {|ln|
                    ln.chomp!
                    Readline::HISTORY.push(ln) if ln.length>0
                }
            rescue
            end
            @stop=false
            while(!@stop)
                sh=@shell ? " "+@shell : ""
                begin
                    cmd = Readline.readline("#{@name}#{sh}>", true)
                    Readline::HISTORY.pop if cmd=='' || (Readline::HISTORY.length>1 && cmd==Readline::HISTORY[-2])
                    runCommand(cmd)
                rescue StandardError => e
                    puts @col.red("Error: #{e.to_s()}")
                    puts e.backtrace if App::get().logger.level == Logger::DEBUG
                end
            end
            return 0
        end


        def run()
            begin
                if ARGV.length()==0
                    commandInterface() if @cmdInterface
                    if !@cmdInterface
                        puts "Command not specified. Known commands are:"
                        runCommand('help')
                    end
                else
                    if (@cmds[ARGV[0]])
                        #check command
                        runCommand(ARGV.join(' '))
                        commandInterface() if @shell
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
