module Resedit

class BitConverter

	def self.bits2Bytes(bits, width)
		i=0
		res=[]
		while i<bits.length do
			buf=0
			cw=0
			bsz=0
			while cw<width do
				if bsz==0
					buf = bits[i]
					i+=1
					bsz=8
				end
				bsz-=1
				cw+=1
				res << ((buf>>bsz) & 1)
			end
		end
		return res
	end

end

end