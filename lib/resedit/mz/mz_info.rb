

module Resedit
    class MZInfo
        def initialize(mz, what)
            @mz=mz
            if (what == "header")
                header()
            elsif what == "reloc"
                reloc()
            else
                raise "Unknown object: " + what
            end
        end

        def header()
            h = @mz.header
            puts "MZ #{@mz.name}:"
            puts sprintf("Magic:\t\t\t0x%4.4X\nLastBlockSizeInBytes:\t0x%4.4X\nBlocks:\t\t\t0x%4.4X", h.magic, h.lastBlockBts, h.blocks)
            puts sprintf("RelocationTableEntries:\t0x%4.4X\nHeaderSizeInParagraphs:\t0x%4.4X", h.relocs, h.headerPara)
            puts sprintf("MinExtraParagraphs:\t0x%4.4X\nMaxExtraParagraphs:\t0x%4.4X", h.minExtraPara, h.maxExtraPara)
            puts sprintf("SS:\t\t\t0x%4.4X\nSP:\t\t\t0x%4.4X\nChecksum:\t\t0x%4.4X\nIP:\t\t\t0x%4.4X\nCS:\t\t\t0x%4.4X", h.ss, h.sp, h.csum, h.ip, h.cs)
            puts sprintf("RelocTableOffset:\t0x%4.4X\nOverlayNumber:\t\t0x%4.4X", h.relocOfs, h.ovlNum)
            puts
            msz = @mz.header.fsize()
            puts sprintf("mz file size: %d (0x%X)\t\treal file size: %d (0x%X)", msz, msz, @mz.fsize, @mz.fsize)
            puts sprintf("header size: 0x%X", h.headerPara * 0x10)
            puts sprintf("code starts at: 0x%X", msz - (h.headerPara * 0x10))
            puts sprintf("reloc table size: 0x%X", h.relocs * 4)
            puts sprintf("free space in header: before relocs 0x%X,  after relocs 0x%X", @mz.relocs.pspace, @mz.relocs.nspace)
        end

        def reloc()
            r = @mz.relocs
            pos = @mz.header.relocOfs
            puts "MZ #{@mz.name} relocs:"
            for i in 0 .. r.count - 1
                rel = r.getReloc(i)
                puts sprintf("%4.4X\t%4.4X:%4.4X", pos, rel[1], rel[0])
                pos += 4
            end
        end


    end
end
