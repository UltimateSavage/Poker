def convert(x):
	out = []
	suit = 0
	card = 0
	for i in x:
		if i%13 == 0:
			suit = (i//13)-1
			card = 13
		elif i%13 ==1:
			card = 14
		else:
			suit = i//13
			card = i%13
		if suit == 0: out.append((card,"C"))
		if suit == 1: out.append((card,"D"))
		if suit == 2: out.append((card,"H"))
		if suit == 3: out.append((card,"S"))
	print(out[0],out[2])
	print(out[1],out[3])
	print(out[4:])