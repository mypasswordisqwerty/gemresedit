require 'resedit/app/app_command'
require 'fileutils'

module Resedit

    class ExportCommand < AppCommand
        def initialize(name)
            super([name])
        end
        def job(params)
            raise 'Not implemented'
        end
    end


    class ImportCommand < AppCommand
        def initialize(name)
            super([name])
        end
        def job(params)
            raise 'Not implemented'
        end
    end


    class ConvertCommand < AppCommand

        attr_reader :fname


        def initialize(name, fname)
            super([name])
            addParam('action','import/export action')
            addParam('file','file to import/export')
            addOption('output','o',nil,'converted file name')
            @fname=fname
        end


        def getOutName()
            return File.basename(@resname,File.extname(@resname))
        end

        def backup()
            bname=@resname+'.bak'
            FileUtils.cp(@resname,bname) if ! File.exist?(bname)
            return bname
        end

        def job(params)
            @params=params
            @resname=params['file']
            fname = getOutName()
            fname = params['output'] if params['output']
            if params['action']=='import'
                import(fname)
            elsif params['action']=='export'
                export(fname)
            else
                raise "Unknown action #{params['action']}. import or export expected."
            end

        end

        def import(infile)
            raise 'Not implemented'
        end

        def export(outfile)
            raise 'Not implemented'
        end
    end

end
