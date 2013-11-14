all:
	erlc bully_algo.erl
	
test: all
	./test.sh

clean:
	rm -f *.beam