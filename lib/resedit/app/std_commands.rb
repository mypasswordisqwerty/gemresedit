require 'resedit/app/app_command'

module Resedit

    class VersionCommand < AppCommand
        def initialize
            super(['version','--version'])
        end
        def job(params)
            log('%s v%s %s',App::get().name, App.get().version, App::get().copyright)
        end
    end

    class ExitCommand < AppCommand
        def initialize
            super(['quit','q', 'exit'])
        end
        def job(params)
            App::get().quit();
        end
    end


    class HelpCommand < AppCommand
        def initialize
            super(['help','--help','-h','/?'])
            addParam('command', 'help on specific command', '')
        end
        def job(params)
            App.get().commands.each{|c|
                puts c.names[0]
            }
        end
    end


    class EchoCommand < AppCommand
        def initialize
            super('echo')
            addParam('string', 'echo text', nil, :text)
            addOption('level', 'l', :info, 'echo level', method(:setLevel))
        end

        def setLevel(val, opt)
            case val
            when 'info','i'
                :info
            when 'debug','d'
                :debug
            when 'error','e'
                :error
            end
            raise "unknown level #{val}"
        end


        def job(params)
            case params['level']
            when :debug
                logd(params['string'])
            when :info
                log(params['string'])
            when :error
                loge(params['string'])
            end
        end
    end


    class ScriptCommand < AppCommand
        def initialize
            super(['script', '--script', '-s'])
            addParam('file', 'script file')
        end
        def job(params)
            App::get().logd("running script %s", params['file']);
            script = []
            text=File.open(params['file']).read
            text.gsub!(/\r\n?/, "\n")
            text.each_line {|line|
                script += [App.get().parseCommand(line.chomp())]
            }
            script.each{|cmd|
                cmd[0].run(cmd[1]) if cmd
            }
        end
    end


end
