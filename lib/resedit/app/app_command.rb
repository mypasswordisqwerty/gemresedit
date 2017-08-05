module Resedit

    class AppCommand
        attr_reader :names, :type, :params, :opts, :ohash
        def initialize(names, type=:std)
            @names, @continue = names, type
            @names = [@names] if not @names.kind_of?(Array)
            @opts = {}
            @params = []
            @ohash = {}
            addOption('verbose','v',false, 'verbose output')
            addOption('unverbose',nil,false, 'unverbose output')
            addOption('quiet','q',false, 'supress output')
            addOption('color',nil,false, 'set colored output')
            addOption('uncolor',nil,false, 'unset colored output')
        end

        def addParam(name, descr, default = nil, type=:std)
            @params +=[{:name => name, :def => default, :descr => descr}]
        end

        def addOption(longname, shortname, param, descr, type = :std, setter= proc{|val, opt| val})
            @opts[longname] = {:name => longname, :param => param, :descr => descr, :type => type, :setter => setter}
            @ohash[shortname] = longname if shortname
        end

        def parseParams(params)
            res = {}
            pidx = 0
            idx=0
            @params.each{|p|
                res[p[:name]] = p[:def]
            }
            @opts.each{|k,o|
                res[k] = o[:param]
            }
            while idx<params.length
                p = params[idx]
                idx+=1
                if p[0]=='-'
                    val = true
                    s=p.split('=')
                    if s.length==2
                        val=s[1]
                        p=s[0]
                    end
                    if (p[1]=='-')
                        opt = @opts[p[2..-1]]
                    else
                        opt = @opts[@ohash[p[1..-1]]] || @opts[p[1..-1]]
                    end
                    raise "Unknown option #{p}" if !opt
                    if opt[:param]!=false and val==true
                        raise "No option #{p} value" if idx>=params.length
                        val = params[idx]
                        idx+=1
                    end
                    proc = opt[:setter]
                    res[opt[:name]] = proc.call(val, opt)
                else
                    raise "Unknown param #{p}" if !@params[pidx]
                    if (@params[pidx][:type] == :text)
                        p = params[idx-1..-1]
                        idx=params.length
                    end
                    res[@params[pidx][:name]] = p
                    pidx+=1
                end
            end
            @params.each{|p|
                raise "Expected parameter #{p[:name]}" if res[p[:name]]==nil
            }
            return res
        end

        def run(params)
            App::get().logger.level = Logger::DEBUG if params['verbose']
            App::get().logger.level = Logger::INFO if params['unverbose']
            App::get().logger.level = Logger::ERROR if params['quiet']
            App::get().col.on = true if params['color']
            App::get().col.on = false if params['uncolor']
            job(params)
        end

        def job(params)
            raise "Unimplemented command #{@names[0]}"
        end

        def logd(fmt, *args)
            App::get().logd(fmt,*args)
        end
        def log(fmt, *args)
            App::get().log(fmt,*args)
        end
        def loge(fmt, *args)
            App::get().loge(fmt,*args)
        end
    end

end
