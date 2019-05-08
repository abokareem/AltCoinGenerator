#!/bin/bash -e

# change the following variables to match your new coin
COIN_NAME="BenCoin"
COIN_UNIT="BEC"
MAINNET_PORT="6333"
#TESTNET_PORT="16333"
RPCMAIN_PORT="6332"
#RPCTEST_PORT="16332"
# First letter of the wallet address. Check https://en.bitcoin.it/wiki/Base58Check_encoding or https://en.bitcoin.it/wiki/List_of_address_prefixes
PUBKEY_CHAR="27"
PUBKEY_CHAR_Letter="B"
PUBKEY_CHAR_TEST="85"
MAGIC_1="0x96"
MAGIC_2="0xC8"
MAGIC_3="0xC3"
MAGIC_4="0xD2"

MAGIC_TEST_1="0xC8"
MAGIC_TEST_2="0x96"
MAGIC_TEST_3="0xD2"
MAGIC_TEST_4="0xC3"
# Some newspaper headline that describes something that happened today
PHRASE="Bencoin release 08/05/2019"

# warning: change this to your own pubkey to get the genesis block mining reward
GENESIS_REWARD_PUBKEY=044e0d4bc823e20e14d66396a64960c993585400c53f1e6decb273f249bfeba0e71f140ffa7316f2cdaaae574e7d72620538c3e7791ae9861dfe84dd2955fc85e8

# dont chnage the following variables unless you know what you are doing
LITECOIN_BRANCH=0.8
LITECOIN_REPOS=https://github.com/litecoin-project/litecoin.git
GENESISHZERO_REPOS=https://github.com/lhartikk/GenesisH0

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

generate_genesis_block()
{
	if [ ! -d GenesisH0 ]; then
		git clone $GENESISHZERO_REPOS
		pushd GenesisH0
	else
		pushd GenesisH0
		git pull
	fi
	
	if [ ! -f ${COIN_NAME}-main.txt ]; then
		echo "Mining genesis block... this procedure can take many hours of cpu work.."
		python genesis.py -a script -z "$PHRASE" -p $GENESIS_REWARD_PUBKEY 2>&1 | tee ${COIN_NAME}-main.txt
	else
		echo "Genesis block already mined.."
		cat ${COIN_NAME}-main.txt
	fi
	
	if [ ! -f ${COIN_NAME}-test.txt ]; then
        echo "Mining genesis block of test network... this procedure can take many hours of cpu work.."
        python genesis.py  -t 1486949366 -a scrypt -z "$PHRASE" -p $GENESIS_REWARD_PUBKEY 2>&1 | tee ${COIN_NAME}-test.txt
    else
        echo "Genesis block already mined.."
        cat ${COIN_NAME}-test.txt
    fi

    if [ ! -f ${COIN_NAME}-regtest.txt ]; then
        echo "Mining genesis block of regtest network... this procedure can take many hours of cpu work.."
        python genesis.py -t 1296688602 -b 0x207fffff -n 0 -a scrypt -z "$PHRASE" -p $GENESIS_REWARD_PUBKEY 2>&1 | tee ${COIN_NAME}-regtest.txt
    else
        echo "Genesis block already mined.."
        cat ${COIN_NAME}-regtest.txt
    fi
	
	popd
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
		$SED -i "s/ltc/$COIN_UNIT_LOWER/g" $i
		$SED -i "s/9333/$MAINNET_PORT/g" $i
		#$SED -i "s/19333/$TESTNET_PORT/g" $i
		$SED -i "s/9332/$RPCMAIN_PORT/g" $i
		#$SED -i "s/19332/$RPCTEST_PORT/g" $i
    done
	
	$SED -i "s/PUBKEY_ADDRESS = 48/PUBKEY_ADDRESS = $PUBKEY_CHAR/g" src/base58.h
	$SED -i "s/addresses start with L/addresses start with $PUBKEY_CHAR_Letter/g" src/base58.h
	$SED -i "s/PUBKEY_ADDRESS_TEST = 111/PUBKEY_ADDRESS_TEST = $PUBKEY_CHAR_TEST/g" src/base58.h
	
	openssl ecparam -genkey -name secp256k1 -out alertkey.pem
	openssl ec -in alertkey.pem -text > alertkey.hex
	rm alertkey.pem
	openssl ecparam -genkey -name secp256k1 -out testnetalert.pem
	openssl ec -in testnetalert.pem -text > testnetalert.hex
	rm testnetalert.pem
	openssl ecparam -genkey -name secp256k1 -out genesiscoinbase.pem
	openssl ec -in genesiscoinbase.pem -text > genesiscoinbase.hex
	rm genesiscoinbase.pem
	#$SED -i "s/ltc/$COIN_UNIT_LOWER/g" src/chainparams.cpp
	alertkey="$(cat alertkey.hex | tr -d \\n | sed 's/ //g' | grep -o "[^pub:].:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:.." | sed 's/://g')"
	testnetalert="$(cat testnetalert.hex | tr -d \\n | sed 's/ //g' | grep -o "[^pub:].:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:.." | sed 's/://g')"
	genesiscoinbase="$(cat genesiscoinbase.hex | tr -d \\n | sed 's/ //g' | grep -o "[^pub:].:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:.." | sed 's/://g')"
	
	$SED -i "s/040184710fa689ad5023690c80f3a49c8f13f8d45b8c857fbcbc8bc4a8e4d3eb4b10f4d4604fa08dce601aaf0f470216fe1b51850b4acf21b179c45070ac7b03a9/$alertkey/g" src/alert.cpp
	$SED -i "s/04302390343f91cc401d56d68b123028bf52e5fca1939df127f63c6467cdf9c8e2c14b61104cf817d0b780da337893ecc4aaff1309e536162dabbdb45200ca2b0a/$testnetalert/g" src/alert.cpp
	$SED -i "s/040184710fa689ad5023690c80f3a49c8f13f8d45b8c857fbcbc8bc4a8e4d3eb4b10f4d4604fa08dce601aaf0f470216fe1b51850b4acf21b179c45070ac7b03a9/$genesiscoinbase/g" src/main.cpp
	$SED -i "s/pchMessageStart[0] = 0xfc/pchMessageStart[0] = $MAGIC_TEST_1/g" src/main.cpp
    $SED -i "s/pchMessageStart[1] = 0xc1/pchMessageStart[1] = $MAGIC_TEST_2/g" src/main.cpp
    $SED -i "s/pchMessageStart[2] = 0xb7/pchMessageStart[2] = $MAGIC_TEST_3/g" src/main.cpp
    $SED -i "s/pchMessageStart[3] = 0xdc/pchMessageStart[3] = $MAGIC_TEST_4/g" src/main.cpp
	$SED -i "s/0xfb, 0xc0, 0xb6, 0xdb/$MAGIC_1, $MAGIC_2, $MAGIC_3, $MAGIC_4/g" src/main.cpp
	$SED -i "s;NY Times 05/Oct/2011 Steve Jobs, Apple’s Visionary, Dies at 56;$PHRASE;" src/main.cpp
	
	#open file src/net.cpp line 1171 and delete dns seeds
	#also delete pnSeeds line 1234 with 0x0
	popd
}

build_coin_linux()
{
	#./autogen.sh
	#./configure --disable-tests --disable-bench
	make -f makefile.unix
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
	test)
		generate_genesis_block
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
