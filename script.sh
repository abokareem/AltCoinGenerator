#!/bin/bash -e

# change the following variables to match your new coin
COIN_NAME="BenCoin"
COIN_UNIT="BEC"
# 42 million coins at total (litecoin total supply is 84000000)
TOTAL_SUPPLY="42000000"
MAINNET_PORT="6333"
TESTNET_PORT="16333"
RPCMAIN_PORT="6332"
RPCTEST_PORT="16332"
# Some newspaper headline that describes something that happened today
PHRASE="Bencoin release 08/05/2019"
# First letter of the wallet address. Check https://en.bitcoin.it/wiki/Base58Check_encoding or https://en.bitcoin.it/wiki/List_of_address_prefixes
PUBKEY_CHAR="27"
#PUBKEY_CHAR_Letter="B"
#PUBKEY_CHAR_TEST="85"
# number of blocks to wait to be able to spend coinbase UTXO's
COINBASE_MATURITY="100"
# this is the amount of coins to get as a reward of mining the block of height 1. if not set this will default to 50
#PREMINED_AMOUNT=10000

#MAGIC_1="0x96"
#MAGIC_2="0xC8"
#MAGIC_3="0xC3"
#MAGIC_4="0xD2"

#MAGIC_TEST_1="0xC8"
#MAGIC_TEST_2="0x96"
#MAGIC_TEST_3="0xD2"
#MAGIC_TEST_4="0xC3"

# warning: change this to your own pubkey to get the genesis block mining reward
# use https://www.bitaddress.org/ to generate a new pubkey or run python ./wallet-generator.py and copy the Public Key: string
GENESIS_REWARD_PUBKEY="044e0d4bc823e20e14d66396a64960c993585400c53f1e6decb273f249bfeba0e71f140ffa7316f2cdaaae574e7d72620538c3e7791ae9861dfe84dd2955fc85e8"

CLIENT_VERSION="1.0.0.0"

# dont chnage the following variables unless you know what you are doing
LITECOIN_BRANCH="0.14"
GENESISHZERO_REPOS="https://github.com/lhartikk/GenesisH0"
LITECOIN_REPOS="https://github.com/litecoin-project/litecoin.git"
LITECOIN_PUB_KEY="040184710fa689ad5023690c80f3a49c8f13f8d45b8c857fbcbc8bc4a8e4d3eb4b10f4d4604fa08dce601aaf0f470216fe1b51850b4acf21b179c45070ac7b03a9"
LITECOIN_MERKLE_HASH="97ddfbbae6be97fd6cdf3e7ca13232a3afff2353e29badfab7f73011edd4ced9"
LITECOIN_MAIN_GENESIS_HASH="12a765e31ffd4059bada1e25190f6e98c99d9714d334efa41a195a7e7e04bfe2"
LITECOIN_TEST_GENESIS_HASH="4966625a4b2851d9fdee139e56211a0d88575f59ed816ff5e6a63deb4e3e29a0"
LITECOIN_REGTEST_GENESIS_HASH="530827f38f93b43ed12af0b3ad25a288dc02ed74d6d7857862df51fc56c416f9"

MINIMUM_CHAIN_WORK_MAIN="0x000000000000000000000000000000000000000000000006805c7318ce2736c0"
MINIMUM_CHAIN_WORK_TEST="0x000000000000000000000000000000000000000000000000000000054cb9e7a0"

COIN_NAME_LOWER="$(printf "%s\\n" "${COIN_NAME}" | tr '[:upper:]' '[:lower:]')"
COIN_NAME_UPPER="$(printf "%s\\n" "${COIN_NAME}" | tr '[:lower:]' '[:upper:]')"
COIN_UNIT_LOWER="$(printf "%s\\n" "${COIN_UNIT}" | tr '[:upper:]' '[:lower:]')"

OSVERSION="$(uname -s)"
CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd)"
COIN_DIR="${CURRENT_DIR}/${COIN_NAME_LOWER}"
SECS="5"

set -e #exit on error

printfl()
{
    _printfl__max_len="$(stty size | awk '{print $2; exit}' 2>/dev/null)" || _printfl__max_len="80"
    if [ -n "${1}" ]; then
        _printfl__word_len="$((${#1} + 2))"
        _printfl__sub="$((_printfl__max_len - _printfl__word_len))"
        _printfl__half="$((_printfl__sub / 2))"
        _printfl__other_half="$((_printfl__sub - _printfl__half))"
        printf "%b" "\\033[1m" #white strong
        printf '%*s' "${_printfl__half}" '' | tr ' ' -
        printf "%b" "\\033[7m" #white background
        printf " %s " "${1}"
        printf "%b" "\\033[0m\\033[1m" #white strong
        printf '%*s' "${_printfl__other_half}" '' | tr ' ' -
        printf "%b" "\\033[0m" #back to normal
        printf "\\n"
    else
        printf "%b" "\\033[1m" #white strong
        printf '%*s' "${_printfl__max_len}" '' | tr ' ' -
        printf "%b" "\\033[0m" #back to normal
        printf "\\n"
    fi
}

printfs()
{
    [ -z "${1}" ] && return 1
    printf "%b\\n" "\\033[1m>>>> ${*}\\033[0m"
}

cmd()
{
    [ -z "${1}" ] && return 1
    printf "%s\\n" "[$] $*"
    #LAST_CMD="${*}"
    "$@"
}

printfv()
{
    [ -z "${1}" ] && return 1
    printf "%b\\n" "\\033[1m ${1}\\033[0m ${2}"
}

header()
{
    clear
    printfl "Altcoin Generator"
    printf "\\n"
    printfv "Updates:" "https://github.com/bespike/AltcoinGenerator"
    printf "\\n"
    printf "%s\\n" "Current configuration (edit the script to change it):"
    printf "\\n"
    printfv "Coin Name     :" "${COIN_NAME} / ${COIN_UNIT}"
    printfv "Total Supply  :" "${TOTAL_SUPPLY}"
    printfv "Premined coins:" "${PREMINED_AMOUNT:-none}"
    printfv "Base Maturity :" "${COINBASE_MATURITY}"
    printfv "Main NET Port :" "${MAINNET_PORT}"
    printfv "Test NET Port :" "${TESTNET_PORT}"
    printfv "Default Chain :" "${CHAIN:-main}"
    printfv "Client Version:" "${CLIENT_VERSION} / Copyright $(date +%Y)"
    printfv "Genesis Reward PubKey:" "${GENESIS_REWARD_PUBKEY}"
    printf "\\n"
    printf "%s" "Continuing in ${SECS} seconds, press Ctrl-c to cancel the operation ..."
    sleep "${SECS}"
    printf "\\n"
}

footer()
{
	printfl "DONE"
}

#install_deps()
#{
#	sudo bash -c "echo deb http://ppa.launchpad.net/bitcoin/bitcoin/ubuntu xenial main >> /etc/apt/sources.list"
#	sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv D46F45428842CE5E
#	sudo apt update
#	sudo apt upgrade
#	sudo apt -y install git build-essential libboost-all-dev libssl-dev
#	sudo apt -y install ccache git libboost-system1.58.0 libboost-filesystem1.58.0 libboost-program-options1.58.0 libboost-thread1.58.0 libboost-chrono1.58.0 libssl1.0.0 libevent-pthreads-2.0-5 libevent-2.0-5 build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev libdb4.8-dev libdb4.8++-dev libminiupnpc-dev libzmq3-dev libqt5gui5 libqt5core5a libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev protobuf-compiler libqrencode-dev python-pip
#	pip install --upgrade pip
#	pip install construct==2.5.2 scrypt
#}

generate_genesis_block()
{
	printfl "Generating Genesis Block"
	mkdir -p "${COIN_DIR}"
	if [ ! -d "${COIN_DIR}/GenesisH0" ]; then
	(
		cd "${COIN_DIR}"
		printfs "Cloning GenesisH0 repository ..."
		cmd git clone "${GENESISHZERO_REPOS}" "${COIN_DIR}/GenesisH0"
	)
	else
	(
		cd "${COIN_DIR}/GenesisH0"
		printfs "Updating GenesisH0 repository ..."
		cmd git pull
	)
	fi
	
#	if [ ! -f ${COIN_NAME}-main.txt ]; then
#		echo "Mining genesis block... this procedure can take many hours of cpu work.."
#		python genesis.py -a scrypt -z "$PHRASE" -p $GENESIS_REWARD_PUBKEY 2>&1 | tee ${COIN_NAME}-main.txt
#	else
#		echo "Genesis block already mined.."
#		cat ${COIN_NAME}-main.txt
#	fi
	
#	if [ ! -f ${COIN_NAME}-test.txt ]; then
#		echo "Mining genesis block of test network... this procedure can take many hours of cpu work.."
#        python genesis.py  -t 1486949366 -a scrypt -z "$PHRASE" -p $GENESIS_REWARD_PUBKEY 2>&1 | tee ${COIN_NAME}-test.txt
#    else
#        echo "Genesis block already mined.."
#        cat ${COIN_NAME}-test.txt
#    fi

#    if [ ! -f ${COIN_NAME}-regtest.txt ]; then
#        echo "Mining genesis block of regtest network... this procedure can take many hours of cpu work.."
#        python genesis.py -t 1296688602 -b 0x207fffff -n 0 -a scrypt -z "$PHRASE" -p $GENESIS_REWARD_PUBKEY 2>&1 | tee ${COIN_NAME}-regtest.txt
#    else
#        echo "Genesis block already mined.."
#        cat ${COIN_NAME}-regtest.txt
#    fi
	
#	MAIN_PUB_KEY=$(cat ${COIN_NAME}-main.txt | grep "^pubkey:" | $SED 's/^pubkey: //')
#    MERKLE_HASH=$(cat ${COIN_NAME}-main.txt | grep "^merkle hash:" | $SED 's/^merkle hash: //')
#    TIMESTAMP=$(cat ${COIN_NAME}-main.txt | grep "^time:" | $SED 's/^time: //')
#    BITS=$(cat ${COIN_NAME}-main.txt | grep "^bits:" | $SED 's/^bits: //')

#    MAIN_NONCE=$(cat ${COIN_NAME}-main.txt | grep "^nonce:" | $SED 's/^nonce: //')
#    TEST_NONCE=$(cat ${COIN_NAME}-test.txt | grep "^nonce:" | $SED 's/^nonce: //')
#    REGTEST_NONCE=$(cat ${COIN_NAME}-regtest.txt | grep "^nonce:" | $SED 's/^nonce: //')

#    MAIN_GENESIS_HASH=$(cat ${COIN_NAME}-main.txt | grep "^genesis hash:" | $SED 's/^genesis hash: //')
#    TEST_GENESIS_HASH=$(cat ${COIN_NAME}-test.txt | grep "^genesis hash:" | $SED 's/^genesis hash: //')
#    REGTEST_GENESIS_HASH=$(cat ${COIN_NAME}-regtest.txt | grep "^genesis hash:" | $SED 's/^genesis hash: //')
	
#	popd
}

#clone_coin()
#{
#	if [ -d $COIN_NAME_LOWER ]; then
#		echo "Warning: $COIN_NAME_LOWER already exist. Not replacing any values"
#		return 0
#	fi
#	if [ ! -d "litecoin-master" ]; then
#		# clone litecoin and keep local cache
#		git clone -b $LITECOIN_BRANCH $LITECOIN_REPOS litecoin-master
#	else
#		echo "Updating master branch"
#		pushd litecoin-master
#		git pull
#		popd
#	fi
	
#	git clone -b $LITECOIN_BRANCH litecoin-master $COIN_NAME_LOWER
	
#	pushd $COIN_NAME_LOWER
	
	#change src/rpcrawtransaction.cpp line 242
	# const CScriptID& hash = boost get<const CScriptID&>(address);
	# to
	# const CScriptID& hash = boost get<CScriptID>(address);
#	$SED -i "s/get<const CScriptID&>(address);/get<CScriptID>(address);/g" src/rpcrawtransaction.cpp
	
	# now replace all litecoin references to the new coin name
#    for i in $(find . -type f | grep -v "^./.git"); do
#        $SED -i "s/Litecoin/$COIN_NAME/g" $i
#        $SED -i "s/litecoin/$COIN_NAME_LOWER/g" $i
#        $SED -i "s/LITECOIN/$COIN_NAME_UPPER/g" $i
#        $SED -i "s/LTC/$COIN_UNIT/g" $i
#		$SED -i "s/ltc/$COIN_UNIT_LOWER/g" $i
#		$SED -i "s/9333/$MAINNET_PORT/g" $i
#		#$SED -i "s/19333/$TESTNET_PORT/g" $i
#		$SED -i "s/9332/$RPCMAIN_PORT/g" $i
		#$SED -i "s/19332/$RPCTEST_PORT/g" $i
#    done
	
#	$SED -i "s/PUBKEY_ADDRESS = 48/PUBKEY_ADDRESS = $PUBKEY_CHAR/g" src/base58.h
#	$SED -i "s/addresses start with L/addresses start with $PUBKEY_CHAR_Letter/g" src/base58.h
#	$SED -i "s/PUBKEY_ADDRESS_TEST = 111/PUBKEY_ADDRESS_TEST = $PUBKEY_CHAR_TEST/g" src/base58.h
	
#	openssl ecparam -genkey -name secp256k1 -out alertkey.pem
#	openssl ec -in alertkey.pem -text > alertkey.hex
#	rm alertkey.pem
#	openssl ecparam -genkey -name secp256k1 -out testnetalert.pem
#	openssl ec -in testnetalert.pem -text > testnetalert.hex
#	rm testnetalert.pem
#	openssl ecparam -genkey -name secp256k1 -out genesiscoinbase.pem
#	openssl ec -in genesiscoinbase.pem -text > genesiscoinbase.hex
#	rm genesiscoinbase.pem
	#$SED -i "s/ltc/$COIN_UNIT_LOWER/g" src/chainparams.cpp
#	alertkey="$(cat alertkey.hex | tr -d \\n | sed 's/ //g' | grep -o "[^pub:].:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:.." | sed 's/://g')"
#	testnetalert="$(cat testnetalert.hex | tr -d \\n | sed 's/ //g' | grep -o "[^pub:].:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:.." | sed 's/://g')"
#	genesiscoinbase="$(cat genesiscoinbase.hex | tr -d \\n | sed 's/ //g' | grep -o "[^pub:].:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:..:.." | sed 's/://g')"
	
#	$SED -i "s/040184710fa689ad5023690c80f3a49c8f13f8d45b8c857fbcbc8bc4a8e4d3eb4b10f4d4604fa08dce601aaf0f470216fe1b51850b4acf21b179c45070ac7b03a9/$alertkey/g" src/alert.cpp
#	$SED -i "s/04302390343f91cc401d56d68b123028bf52e5fca1939df127f63c6467cdf9c8e2c14b61104cf817d0b780da337893ecc4aaff1309e536162dabbdb45200ca2b0a/$testnetalert/g" src/alert.cpp
#	$SED -i "s/040184710fa689ad5023690c80f3a49c8f13f8d45b8c857fbcbc8bc4a8e4d3eb4b10f4d4604fa08dce601aaf0f470216fe1b51850b4acf21b179c45070ac7b03a9/$genesiscoinbase/g" src/main.cpp
#	$SED -i "s/pchMessageStart[0] = 0xfc/pchMessageStart[0] = $MAGIC_TEST_1/g" src/main.cpp
#    $SED -i "s/pchMessageStart[1] = 0xc1/pchMessageStart[1] = $MAGIC_TEST_2/g" src/main.cpp
#    $SED -i "s/pchMessageStart[2] = 0xb7/pchMessageStart[2] = $MAGIC_TEST_3/g" src/main.cpp
#    $SED -i "s/pchMessageStart[3] = 0xdc/pchMessageStart[3] = $MAGIC_TEST_4/g" src/main.cpp
#	$SED -i "s/0xfb, 0xc0, 0xb6, 0xdb/$MAGIC_1, $MAGIC_2, $MAGIC_3, $MAGIC_4/g" src/main.cpp
#	$SED -i "s;NY Times 05/Oct/2011 Steve Jobs, Apple’s Visionary, Dies at 56;$PHRASE;" src/main.cpp
	
#	$SED -i "s/1317972665/$TIMESTAMP/" src/main.cpp
#	$SED -i "0,/0x1e0ffff0/s//$BITS/" src/main.cpp
#	$SED -i "0,/2084524493/s//$MAIN_NONCE/" src/main.cpp
#	$SED -i "0,/385270584/s//$TEST_NONCE/" src/main.cpp
	#$SED -i "0,/1296688602, 0/s//1296688602, $REGTEST_NONCE/"
	
#	$SED -i "s/$LITECOIN_PUB_KEY/$MAIN_PUB_KEY/" src/main.cpp
#    $SED -i "s/$LITECOIN_MERKLE_HASH/$MERKLE_HASH/" src/main.cpp
    #$SED -i "s/$LITECOIN_MERKLE_HASH/$MERKLE_HASH/" 
	
#	$SED -i "0,/$LITECOIN_MAIN_GENESIS_HASH/s//$MAIN_GENESIS_HASH/" src/main.cpp
    #$SED -i "0,/$LITECOIN_TEST_GENESIS_HASH/s//$TEST_GENESIS_HASH/"
    #$SED -i "0,/$LITECOIN_REGTEST_GENESIS_HASH/s//$REGTEST_GENESIS_HASH/"
	
	#open file src/net.cpp line 1171 and delete dns seeds
	#also delete pnSeeds line 1234 with 0x0
#	popd
#}

#build_coin_linux()
#{
	#./autogen.sh
	#./configure --disable-tests --disable-bench
#	make -f makefile.unix
#}

progname="$(basename "${0}")"

case $OSVERSION in
    Linux*)
        SED=sed
    ;;
    *)
        echo "This script only works on Linux"
        exit 1
    ;;
esac

if ! command -v "git" >/dev/null 2>&1; then
	echo "Please install git first"
	exit 1
fi

case $1 in
	install)
		install_deps
    ;;
	make_coin)
		generate_genesis_block
		clone_coin
	;;
	build_coin)
		build_coin_linux
	;;
	start)
		header
		generate_genesis_block
	;;
	*)
        cat <<EOF
Usage: ${progname} (start|stop|remove_nodes|clean_up)
 - start: build and run your new coin
 - clean_up: WARNING: this will remove source code, genesis block information and all data. (to start from scratch)
EOF
    ;;
esac
