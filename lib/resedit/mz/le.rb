require 'resedit/classes/exefile'

module Resedit

    class LEHeader < ExeHeader
        MAGIC = [0x454C, 0x584C, 0x434C]
        HSIZE = 0xAC
        HDRDESCR = [:Magic, :BOrd, :WOrd, :FormatLevel, :CpuType, :OsType, :ModuleVersion, :ModuleFlags, :ModulePages, :EIPObj, :EIP, :ESPObj, :ESP,
                    :PageSize, :PageShift, :FixupSize, :FixupCsum, :LoaderSize, :LoaderCsum, :ObjectTableOfs, :ObjectsInModule,
                    :ObjectPageOfs, :ObjectIterOfs, :ResourceTableOfs, :ResourceTableEntries, :ResidentTableOfs, :EntryTableOfs,
                    :ModuleDirectivesOfs, :ModuleDirectives, :FixupPageOfs, :FixupRecordOfs, :ImportTblOfs, :ImportEntries, :ImportProcOfs,
                    :PerPageCsum, :DataPagesOfs, :PreloadPages, :NonResTableOfs, :NonResTableLen, :NonResTableCsum, :AutoDSObject,
                    :DebugInfoOfs, :DebugInfoLen, :InstancePreload, :InstanceDemand, :Heapsize]
        HDRUNPACK = "vHHVvvV40"

        #    00h | "L"   "X" |B-ORD|W-ORD|     FORMAT LEVEL      |
        #     +-----+-----+-----+-----+-----+-----+-----+-----+
        # 08h | CPU TYPE  |  OS TYPE  |    MODULE VERSION     |
        #     +-----+-----+-----+-----+-----+-----+-----+-----+
        # 10h |     MODULE FLAGS      |   MODULE # OF PAGES   |
        #     +-----+-----+-----+-----+-----+-----+-----+-----+
        # 18h |     EIP OBJECT #      |          EIP          |
        #     +-----+-----+-----+-----+-----+-----+-----+-----+
        # 20h |     ESP OBJECT #      |          ESP          |
        #     +-----+-----+-----+-----+-----+-----+-----+-----+
        # 28h |       PAGE SIZE       |   PAGE OFFSET SHIFT / LE: last page bytes !!!  |
        #     +-----+-----+-----+-----+-----+-----+-----+-----+
        # 30h |  FIXUP SECTION SIZE   | FIXUP SECTION CHECKSUM|
        #     +-----+-----+-----+-----+-----+-----+-----+-----+
        # 38h |  LOADER SECTION SIZE  |LOADER SECTION CHECKSUM|
        #     +-----+-----+-----+-----+-----+-----+-----+-----+
        # 40h |    OBJECT TABLE OFF   |  # OBJECTS IN MODULE  |
        #     +-----+-----+-----+-----+-----+-----+-----+-----+
        # 48h | OBJECT PAGE TABLE OFF | OBJECT ITER PAGES OFF |
        #     +-----+-----+-----+-----+-----+-----+-----+-----+
        # 50h | RESOURCE TABLE OFFSET |#RESOURCE TABLE ENTRIES|
        #     +-----+-----+-----+-----+-----+-----+-----+-----+
        # 58h | RESIDENT NAME TBL OFF |   ENTRY TABLE OFFSET  |
        #     +-----+-----+-----+-----+-----+-----+-----+-----+
        # 60h | MODULE DIRECTIVES OFF | # MODULE DIRECTIVES   |
        #     +-----+-----+-----+-----+-----+-----+-----+-----+
        # 68h | FIXUP PAGE TABLE OFF  |FIXUP RECORD TABLE OFF |
        #     +-----+-----+-----+-----+-----+-----+-----+-----+
        # 70h | IMPORT MODULE TBL OFF | # IMPORT MOD ENTRIES  |
        #     +-----+-----+-----+-----+-----+-----+-----+-----+
        # 78h |  IMPORT PROC TBL OFF  | PER-PAGE CHECKSUM OFF |
        #     +-----+-----+-----+-----+-----+-----+-----+-----+
        # 80h |   DATA PAGES OFFSET FROM MZ !!!  |    #PRELOAD PAGES     |
        #     +-----+-----+-----+-----+-----+-----+-----+-----+
        # 88h | NON-RES NAME TBL OFF  | NON-RES NAME TBL LEN  |
        #     +-----+-----+-----+-----+-----+-----+-----+-----+
        # 90h | NON-RES NAME TBL CKSM |   AUTO DS OBJECT #    |
        #     +-----+-----+-----+-----+-----+-----+-----+-----+
        # 98h |    DEBUG INFO OFF     |    DEBUG INFO LEN     |
        #     +-----+-----+-----+-----+-----+-----+-----+-----+
        # A0h |   #INSTANCE PRELOAD   |   #INSTANCE DEMAND    |
        #     +-----+-----+-----+-----+-----+-----+-----+-----+
        # A8h |       HEAPSIZE        |
        #

        # Object Table
        #     +-----+-----+-----+-----+-----+-----+-----+-----+
        # 00h |     VIRTUAL SIZE      |    RELOC BASE ADDR    |
        #     +-----+-----+-----+-----+-----+-----+-----+-----+
        # 08h |     OBJECT FLAGS      |    PAGE TABLE INDEX   |
        #     +-----+-----+-----+-----+-----+-----+-----+-----+
        # 10h |  # PAGE TABLE ENTRIES |       RESERVED        |
        #     +-----+-----+-----+-----+-----+-----+-----+-----+

        attr_reader :tables

        def initialize(exe, file, fsize)
            @_tablesOrig = nil
            @sofs = file.tell()
            super(exe, file, fsize)
        end

        def loadTables(file)
            if @_tablesOrig==nil
                objtblend = @sofs+@info[:ObjectTableOfs]+@info[:ObjectsInModule]*0x18
                #addData(file, objtblend-file.tell())
                objtblend = @sofs+@info[:ObjectPageOfs]+@info[:ModulePages]*8
                addData(file, objtblend-file.tell())
            end
            tbl = {:Objects => [], :Pages => []}
            ofs = 0
            for i in 0..@info[:ObjectsInModule]-1
                descr = getData(@info[:ObjectTableOfs]+i*0x18, 0x18).unpack("V*")
                tbl[:Objects] += [descr]
                @exe.env.set("seg#{i}".to_sym, ofs.to_s)
                ofs += descr[4]*@info[:PageSize]
            end
            for i in 0..@info[:ModulePages]-1
                tbl[:Pages] += getData(@info[:ObjectPageOfs]+i*4, 4).unpack("V")
            end
            if @_tablesOrig==nil
                @tables = @_tablesOrig = tbl
            end
            return tbl
        end

        def loadTail(file);
            addData(file, headerSize() + @sofs - file.tell())
        end

        def readRelocs()
            def read(pos,cnt, unp); [getData(@info[:FixupRecordOfs]+pos, cnt).unpack(unp),pos+cnt] end
            ret = {}
            pgs = getData(@info[:FixupPageOfs], 4*(@info[:ModulePages]+1)).unpack("V*")
            for i in 0..@info[:ModulePages]-1
                pos = pgs[i]
                op = @tables[:Pages][i]
                pgofs = ((op>>16) + ((op>>8) & 0xFF) -1) * @info[:PageSize]
                ret[pgofs] = {}
                while pos<pgs[i+1]
                    v,pos = read(pos, 5, "CCvC")
                    raise "Unknown fixup type #{v[0]} #{v[1]}" if (v[0]!=7 && v[0]!=2) || (v[1] & ~0x10 !=0 )
                    trg, pos=read(pos, v[1]==0x10 ? 4 : 2,v[1]==0x10 ? "V" : "v")
                    next if v[2]>0x7FFF
                    ofs = pgofs+v[2]
                    ret[pgofs][pgofs+v[2]] = @tables[:Objects][v[3]-1][1]+trg[0]
                end
            end
            return ret
        end


        def mode(how)
            super(how)
            if @mode == HOW_ORIGINAL
                @tables = @_tablesOrig
            else
                @_tables = loadTables(nil) if !@_tables
                @tables = @_tables
            end
        end

        def headerSize(); @info[:DataPagesOfs]-@exe.mzSize end

        def fileSize(); headerSize()+(@info[:ModulePages]-1)*@info[:PageSize]+@info[:PageShift] end
        def entry; sprintf("0x%08X", @info[:EIP]) end

        def print(what, how=nil)
            ret = super(what, how)
            if what=="tables"
                puts "Objects: #{@tables[:Objects].map{|o| o.map{|v| v.to_s(16)}}}"
                puts "Pages: #{@tables[:Pages].map{|x| x.to_s(16)}}"
                return true
            end
            return ret
        end
    end

    class LEBody < ExeBody

        def initialize(exe, file, fsize)
            super(exe, file, fsize)
        end

        def sections()
            if !@sex
                ofs = 0
                @sex=[]
                @exe.header.tables[:Objects].each{|descr|
                    sz = descr[4] * @exe.header.info[:PageSize]
                    if sz!=0
                        @sex += [[descr[1], ofs, sz]]
                        ofs += sz
                    end
                }
            end
            @sex
        end

        def relocations()
            if !@relocs
                @relocs = @exe.header.readRelocs().sort_by{|k,v| k}.reverse.to_h
                @relocs.each{|k,v|
                    @relocs[k] = v.sort_by{|k2,v2| k2}.reverse.to_h
                }
            end
            @relocs
        end

        def formatAddress(raw)
            return sprintf("%08X %08X", raw, raw2addr(raw))
        end

        def raw2addr(ofs)
            s = sections.find{|s| s[1]<=ofs && s[1]+s[2]>ofs}
            raise "Not raw offset #{ofs.to_s(16)}" if !s
            return s[0]+ofs-s[1]
        end

        def addr2raw(addr)
            s = sections.find{|s| s[0]<=addr && s[0]+s[2]>addr}
            raise "Not virtual address #{addr.to_s(16)}" if !s
            return s[1]+addr-s[0]
        end

        def readRelocated(ofs, size);
            rel = relocations()
            d = getData(ofs, size)
            @relocs.each{|o,v|
                next if o>ofs+size
                v.each{|a, r|
                    next if a>ofs+size
                    break if a<ofs
                    pos = a-ofs
                    d = d[0,pos] + [r].pack("V") + (d[pos+4..-1] or '')
                }
                break if o<ofs
            }
            return d[0,size]
        end

    end


    class LE < ExeFile
        HDRCLASS = LEHeader
        BODYCLASS = LEBody
        MODE = 32

        attr_reader :mzSize

        def load(file, sz, prev)
            @mzSize = prev.header.fileSize()
            super(file, sz, prev)
        end

    end

end
