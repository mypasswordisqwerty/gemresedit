require 'resedit/app/app_command'

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
    def initialize(name, ext)
        super([name])
        addParam('action','import/export action')
        addParam('file','file to import/export')
        addOption('file','f','output','converted file name')
    end


    def getOutName(resname)
        return File.basename(resname,File.extname(resname))
    end

    def job(params)
        resname=params['file']
        fname = getOutName(resname)
        fname = params['output'] if params['output']
        if params['action']=='import'
            import(resname, fname)
        elsif params['action']=='export'
            export(resname, fname)
        else
            raise "Unknown action #{params['action']}. import or export expected."
        end
                
    end

    def import(resname, infile)
        raise 'Not implemented'
    end

    def export(resname, outfile)
        raise 'Not implemented'
    end
end

end