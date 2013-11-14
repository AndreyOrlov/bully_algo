num_nodes=3
nodes="["
for i in $(seq 1 $num_nodes)
do
        nodes=$nodes"{node$i@$(hostname), $i}"
        if (( $i < $num_nodes )); then
                nodes=$nodes", "        
        fi
        
done
nodes=$nodes"]"
echo $nodes

for i in $(seq 1 $num_nodes) 
do
        gnome-terminal -x erl -eval "bully_algo:run($i, $nodes)." &
        sleep 1
done