#!/usr/bin/env bash

PWD=$(pwd)
if docker ps --filter "name=mysqldb" --filter "status=running" | grep -q mysqldb; then
    echo "mysqldb is running !!!"
else
    ## 判断文件夹存在不。
    [ -d "${PWD}/data/mysqldb/data" ] || mkdir -p "${PWD}/data/mysqldb/data"
    ####################### 创建数据库 #######################
    docker run --name mysqldb -v "${PWD}"/data/mysqldb/data:/var/lib/mysql --restart=always \
        -e MYSQL_ROOT_PASSWORD=mysqldb -e MYSQL_DATABASE=stock_data -e TZ=Asia/Shanghai \
        -p 3306:3306 -d mysql:5.7 --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
fi

#检查mysqldb是否启动，等待5秒钟，再次检查mysqldb启动
count=0
until docker ps --filter "name=mysqldb" --filter "status=running" | grep -q mysqldb; do
    sleep 1
    count=$((count + 1))
    if [ $count -ge 10 ]; then
        echo "mysqldb is not running !!!"
        exit 1
    fi
done

#检查stock启动
if docker ps --filter "name=stock" --filter "status=running" | grep -q stock; then
    echo "stop & rm stock ..."
    docker stop stock && docker rm -f stock
fi

echo "starting stock ..."
# 1 是开发环境。映射本地代码。
if [ "$1" == 1 ]; then
    echo "#############  run dev ############# "
    # /data/stock 是代码目录 -v /data/stock:/data/stock 是开发模式。
    mkdir -p "${PWD}"/notebooks
    #  测试使用，自己需注册，申请：https://tushare.pro/user/token
    docker run -itd --link=mysqldb --name stock \
        -e LANG=zh_CN.UTF-8 -e LC_CTYPE=zh_CN.UTF-8 -e PYTHONIOENCODING=utf-8 \
        -p 8888:8888 -p 9999:9999 --restart=always \
        -v "${PWD}"/jobs:/data/stock/jobs \
        -v "${PWD}"/libs:/data/stock/libs \
        -v "${PWD}"/web:/data/stock/web \
        -v "${PWD}"/supervisor:/data/supervisor \
        -v "${PWD}"/notebooks:/data/notebooks \
        -v "${PWD}"/data/logs:/data/logs \
        pythonstock/pythonstock:latest
else
    echo "############# run online ############# "
    # /data/stock 是代码目录 -v /data/stock:/data/stock 是开发模式。
    docker run -itd --link=mysqldb --name stock \
        -p 8888:8888 -p 9999:9999 --restart=always \
        pythonstock/pythonstock:latest
fi
