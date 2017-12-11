require 'resedit/classes/exefile'

module Resedit

    class BWHeader < ExeHeader
        MAGIC = 0x5742
        HSIZE = 0xB0
        HDRDESCR = [:Magic, :LastPageBytes, :BlocksInFile, :Reserved1, :Reserved2, :MinAlloc, :MaxAlloc, :SS, :SP, :FirstRelocSel, :IP, :CS,
                    :RuntimeGdtSize, :MAKEPMVer, :NextHeaderPos, :CVInfoOffset, :LastSelUsed, :PMemAlloc, :AllocIncr, :Reserved4, :Options,
                    :TransStackSel, :ExpFlags, :ProgramSize, :GdtImageSize, :FirstSelector, :DefaultMemStrategy, :Reserved5, :TransferBufferSize,
                    :Reserved6, :ExpPath]
        HDRUNPACK = "v14VVv3a6v6CCva48a64"

        # unsigned_16 signature;          /* BW signature to mark valid file  */
        # unsigned_16 last_page_bytes;    /* length of image mod 512          */
        # unsigned_16 pages_in_file;      /* number of 512 byte pages         */
        # unsigned_16 reserved1;
        # unsigned_16 reserved2;
        # unsigned_16 min_alloc;          /* required memory, in KB           */
        # unsigned_16 max_alloc;          /* max KB (private allocation)      */
        # unsigned_16 stack_seg;          /* segment of stack                 */
        # unsigned_16 stack_ptr;          /* initial SP value                 */
        # unsigned_16 first_reloc_sel;    /* huge reloc list selector         */
        # unsigned_16 init_ip;            /* initial IP value                 */
        # unsigned_16 code_seg;           /* segment of code                  */
        # unsigned_16 runtime_gdt_size;   /* runtime GDT size in bytes        */
        # unsigned_16 MAKEPM_version;     /* ver * 100, GLU = (ver+10)*100    */
        # /* end of DOS style EXE header */
        # unsigned_32 next_header_pos;    /* file pos of next spliced .EXP    */
        # unsigned_32 cv_info_offset;     /* offset to start of debug info    */
        # unsigned_16 last_sel_used;      /* last selector value used         */
        # unsigned_16 pmem_alloc;         /* private xm amount KB if nonzero  */
        # unsigned_16 alloc_incr;         /* auto ExtReserve amount, in KB    */
        # unsigned_8  reserved4[6];
        # /* the following used to be referenced as gdtimage[0..1] */
        # unsigned_16 options;            /* runtime options                  */
        # unsigned_16 trans_stack_sel;    /* sel of transparent stack         */
        # unsigned_16 exp_flags;          /* see ef_ constants below          */
        # unsigned_16 program_size;       /* size of program in paras         */
        # unsigned_16 gdtimage_size;      /* size of gdt in file (bytes)      */
        # unsigned_16 first_selector;     /* gdt[first_sel] = gdtimage[0], 0 => 0x80 */
        # unsigned_8  default_mem_strategy;
        # unsigned_8  reserved5;
        # unsigned_16 transfer_buffer_size;   /* default in bytes, 0 => 8KB   */
        # /* the following used to be referenced as gdtimage[2..15] */
        # unsigned_8  reserved6[48];
        # char        EXP_path[64];       /* original .EXP file name  */

        def headerSize(); HSIZE end

        def fileSize(); @info[:BlocksInFile] * BLK + @info[:LastPageBytes] end
        def entry; sprintf("%04X:%04X", @info[:CS], @info[:IP]) end


    end


    class BWBody < ExeBody
    end

    class BW < ExeFile
        HDRCLASS = BWHeader
        BODYCLASS = BWBody

    end

end
