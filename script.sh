#!/bin/bash -e

# change the following variables to match your new coin
COIN_NAME="BenCoin"
COIN_UNIT="BEC"

# dont chnage the following variables unless you know what you are doing
LITECOIN_BRANCH=0.8
LITECOIN_REPOS=https://github.com/litecoin-project/litecoin.git

COIN_NAME_LOWER=$(echo $COIN_NAME | tr '[:upper:]' '[:lower:]')
COIN_NAME_UPPER=$(echo $COIN_NAME | tr '[:lower:]' '[:upper:]')
COIN_UNIT_LOWER=$(echo $COIN_UNIT | tr '[:upper:]' '[:lower:]')

OSVERSION="$(uname -s)"
DIRNAME=$(dirname $0)

install_deps()
{
	sudo bash -c "echo deb http://ppa.launchpad.net/bitcoin/bitcoin/ubuntu xenial main >> /etc/apt/sources.list"
	sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv D46F45428842CE5E
	sudo apt update
	sudo apt upgrade
	sudo apt -y install git build-essential libboost-all-dev libssl-dev
	sudo apt -y install ccache git libboost-system1.58.0 libboost-filesystem1.58.0 libboost-program-options1.58.0 libboost-thread1.58.0 libboost-chrono1.58.0 libssl1.0.0 libevent-pthreads-2.0-5 libevent-2.0-5 build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev libdb4.8-dev libdb4.8++-dev libminiupnpc-dev libzmq3-dev libqt5gui5 libqt5core5a libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev protobuf-compiler libqrencode-dev python-pip
	pip install --upgrade pip
	pip install construct==2.5.2 scrypt
}

clone_coin()
{
	if [ -d $COIN_NAME_LOWER ]; then
		echo "Warning: $COIN_NAME_LOWER already exist. Not replacing any values"
		return 0
	fi
	if [ ! -d "litecoin-master" ]; then
		# clone litecoin and keep local cache
		git clone -b $LITECOIN_BRANCH $LITECOIN_REPOS litecoin-master
	else
		echo "Updating master branch"
		pushd litecoin-master
		git pull
		popd
	fi
	
	git clone -b $LITECOIN_BRANCH litecoin-master $COIN_NAME_LOWER
	
	pushd $COIN_NAME_LOWER
	
	#change src/rpcrawtransaction.cpp line 242
	# const CScriptID& hash = boost get<const CScriptID&>(address);
	# to
	# const CScriptID& hash = boost get<CScriptID>(address);
	$SED -i "s/get<const CScriptID&>(address);/get<CScriptID>(address);/g" src/rpcrawtransaction.cpp
	
	# now replace all litecoin references to the new coin name
    for i in $(find . -type f | grep -v "^./.git"); do
        $SED -i "s/Litecoin/$COIN_NAME/g" $i
        $SED -i "s/litecoin/$COIN_NAME_LOWER/g" $i
        $SED -i "s/LITECOIN/$COIN_NAME_UPPER/g" $i
        $SED -i "s/LTC/$COIN_UNIT/g" $i
    done
	
	$SED -i "s/ltc/$COIN_UNIT_LOWER/g" src/chainparams.cpp
	popd
}

build_coin_linux()
{
	./autogen.sh
	./configure --disable-tests --disable-bench
}

case $OSVERSION in
    Linux*)
        SED=sed
    ;;
    *)
        echo "This script only works on Linux"
        exit 1
    ;;
esac

case $1 in
	install)
		install_deps
    ;;
	make_coin)
		clone_coin
	;;
	build_coin)
		build_coin_linux
	;;
	*)
        cat <<EOF
Usage: $0 (start|stop|remove_nodes|clean_up)
 - start: bootstrap environment, build and run your new coin
 - stop: simply stop the containers without removing them
 - remove_nodes: remove the old docker container images. This will stop them first if necessary.
 - clean_up: WARNING: this will stop and remove docker containers and network, source code, genesis block information and nodes data directory. (to start from scratch)
EOF
    ;;
esac
		

#case $1 in
#    stop)
#        docker_stop_nodes
#    ;;
#    remove_nodes)
#        docker_stop_nodes
#        docker_remove_nodes
#    ;;
#    clean_up)
#        docker_stop_nodes
#        for i in $(seq 2 5); do
#           docker_run_node $i "rm -rf /$COIN_NAME_LOWER /root/.$COIN_NAME_LOWER" &>/dev/null
#        done
#        docker_remove_nodes
#        docker_remove_network
#        rm -rf $COIN_NAME_LOWER
#        if [ "$2" != "keep_genesis_block" ]; then
#            rm -f GenesisH0/${COIN_NAME}-*.txt
#        fi
#        for i in $(seq 2 5); do
#           rm -rf miner$i
#        done
#    ;;
#    start)
#        if [ -n "$(docker ps -q -f ancestor=$DOCKER_IMAGE_LABEL)" ]; then
#            echo "There are nodes running. Please stop them first with: $0 stop"
#            exit 1
#        fi
#        docker_build_image
#        generate_genesis_block
#        newcoin_replace_vars
#        build_new_coin
#        docker_create_network

#        docker_run_node 2 "cd /$COIN_NAME_LOWER ; ./src/${COIN_NAME_LOWER}d $CHAIN -listen -noconnect -bind=$DOCKER_NETWORK.2 -addnode=$DOCKER_NETWORK.1 -addnode=$DOCKER_NETWORK.3 -addnode=$DOCKER_NETWORK.4 -addnode=$DOCKER_NETWORK.5" &
#        docker_run_node 3 "cd /$COIN_NAME_LOWER ; ./src/${COIN_NAME_LOWER}d $CHAIN -listen -noconnect -bind=$DOCKER_NETWORK.3 -addnode=$DOCKER_NETWORK.1 -addnode=$DOCKER_NETWORK.2 -addnode=$DOCKER_NETWORK.4 -addnode=$DOCKER_NETWORK.5" &
#        docker_run_node 4 "cd /$COIN_NAME_LOWER ; ./src/${COIN_NAME_LOWER}d $CHAIN -listen -noconnect -bind=$DOCKER_NETWORK.4 -addnode=$DOCKER_NETWORK.1 -addnode=$DOCKER_NETWORK.2 -addnode=$DOCKER_NETWORK.3 -addnode=$DOCKER_NETWORK.5" &
#        docker_run_node 5 "cd /$COIN_NAME_LOWER ; ./src/${COIN_NAME_LOWER}d $CHAIN -listen -noconnect -bind=$DOCKER_NETWORK.5 -addnode=$DOCKER_NETWORK.1 -addnode=$DOCKER_NETWORK.2 -addnode=$DOCKER_NETWORK.3 -addnode=$DOCKER_NETWORK.4" &

#        echo "Docker containers should be up and running now. You may run the following command to check the network status:
#for i in \$(docker ps -q); do docker exec \$i /$COIN_NAME_LOWER/src/${COIN_NAME_LOWER}-cli $CHAIN getblockchaininfo; done"
#        echo "To ask the nodes to mine some blocks simply run:
#for i in \$(docker ps -q); do docker exec \$i /$COIN_NAME_LOWER/src/${COIN_NAME_LOWER}-cli $CHAIN generate 2  & done"
#        exit 1
#    ;;
#    *)
#        cat <<EOF
#Usage: $0 (start|stop|remove_nodes|clean_up)
# - start: bootstrap environment, build and run your new coin
# - stop: simply stop the containers without removing them
# - remove_nodes: remove the old docker container images. This will stop them first if necessary.
# - clean_up: WARNING: this will stop and remove docker containers and network, source code, genesis block information and nodes data directory. (to start from scratch)
#EOF
#    ;;
#esac
