#template for python scripts which process files line-by-line
#run with pypy3 and pipe file input


import sys

def main():
	for line in sys.stdin.buffer:
		line=line.decode()
		if line.startswith('#'):
			continue#skip commented lines
		#split on tabs
		line=line.rstrip('\n').split('\t')

		#split out info fields
		info=line[-1].split(';')
		#remove labels. 'ref, alt, skew' is the order
		info=[i.split('=')[1] for i in info]
		
        spit=[]
	
	    spit.append(line[0])
		
        print('\t'.join(spit))
		
if __name__=="__main__":
	main()