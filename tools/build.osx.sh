#!/usr/bin/env bash

if [ "$REPO_ROOT" == "" ] ; then REPO_ROOT="$(greadlink -f $(dirname $(greadlink -f $0))/../)" ; fi

# check for build environment, tools and libraries

if [ "$(command -v cmake)" == "" ] ; 
then 
	echo "error: cmake not found." 1>&2
	exit -1
fi

if [ ! -e "$REPO_ROOT/tools/dotnet" ];
then
	echo "dotnet sdk not found, downloading."
	dotnet_url="https://dotnetcli.blob.core.windows.net/dotnet/Sdk/master/dotnet-dev-osx-x64.latest.tar.gz"
	mkdir "$REPO_ROOT/tools/dotnet"
	wget $dotnet_url -O - | tar -xz -C "$REPO_ROOT/tools/dotnet"
fi
export PATH="$REPO_ROOT/tools/dotnet":$PATH

# build Trinity.C
build_trinity_c()
{
	echo "Building Trinity.C"
	mkdir -p "$REPO_ROOT/bin/coreclr" && pushd "$_" || exit -1
	cmake "$REPO_ROOT/src/Trinity.C" || exit -1
	make || exit -1
	cp "$REPO_ROOT/libTrinity.dylib" "$REPO_ROOT/bin/coreclr/libTrinity.dylib" || exit -1
	popd
}

# build Trinity.Core
build_trinity_core()
{
	echo "Building Trinity.Core"
	pushd "$REPO_ROOT/src/Trinity.Core"
	dotnet restore Trinity.Core.NETStandard.sln || exit -1
	dotnet build Trinity.Core.NETStandard.sln || exit -1
	dotnet pack Trinity.Core.NETStandard.sln || exit -1
}

# register local nuget repo, remove GraphEngine.CoreCLR packages in the cache.
setup_nuget_repo()
{
	nuget_repo_name="Graph Engine OSS Local" 
	if [ "$(grep "$nuget_repo_name" ~/.nuget/NuGet/NuGet.Config)" == "" ];
	then
		echo "registering NuGet local repository '$nuget_repo_name'."
		nuget_repo_location=$(printf "%q" "$REPO_ROOT/bin/coreclr")
		sed -i "s#  </packageSources>#    <add key=\"$nuget_repo_name\" value=\"$nuget_repo_location\" \/>\n  <\/packageSources>#g" ~/.nuget/NuGet/NuGet.Config
	fi
	echo "remove local package cache."
	rm -rf ~/.nuget/packages/graphengine.coreclr
}

build_trinity_c
build_trinity_core
setup_nuget_repo

