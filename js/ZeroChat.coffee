class ZeroChat extends ZeroFrame
  init: ->
    @event_site_info = $.Deferred()
    @site_info = null
    @server_info = null

    $.when(@event_site_info).done =>
      @log "event site info"
      @checkUser()

    @addLine "inited!"

  checkUser:()=>
    if @site_info.cert_user_id
      @myDataPath= "data/users/#{@site_info.auth_address}/data.json"  # This is our data file
      #has login info
      @siteInit()
      return

    @cmd "certSelect", [["zeroid.bit"]]

    

  renderAppend:(response)=>
    @log response


  receiveResponse:(response)=>
    #todo use dbQuery
    @log "trying to get my pusher's data ",@myPusherPath
    @cmd "fileGet", {"inner_path":@myPusherPath},(push_data)=>

      @log "my pusher's data #{@myPusherPath} getted"
      pushMessages=JSON.parse(push_data)

      myResponse = pushMessages.response[@site_info.auth_address]
      if myResponse
        #server restart or I'm not logined
        #not sent any request
        @log "I haven't sent any request to site"
        @initRequest()
      else
        #TODO check id not continues problem (server restart while user sent )
        @log "site have my previous response"
        @myData.next_id = response.next_id
        @renderAppend(myResponse)


  writeData:(callback)=>
    @myData.id=@next_id
    json_raw = unescape(encodeURIComponent(JSON.stringify(@myData, undefined, '\t')))
    @cmd "fileWrite", [@myDataPath, btoa(json_raw)], callback


  siteInit:()=>
    @log "getting push_map.json"
    @cmd "fileGet", {"inner_path": "data/push_map.json"}, (push_map_json)=>

      pushMap = JSON.parse(push_map_json)
      @log "push_map.json getted", pushMap
      #TODO support different pushers
      @myPusherPath = "data/users/#{pushMap.pusher[0]}/data.json"

      @log "trying to get my data:",@myDataPath

      @cmd "fileGet", {"inner_path":@myDataPath,"required":false},(my_data)=>


        if my_data
          @myData= JSON.parse(my_data)
          @log "my data ",@myData
          @receiveResponse()
        else
          @log "no my data, create new"
          @next_id=0
          @myData= {"request":{}}
          @writeData (res)=>
            if res is 'ok'
              @receiveResponse()
            else
              @log "error"

          





      
        


  initRequest:()=>
    @log "init request"
    @next_id = 0
    @myData.request={"cmd":"handshake"}
    @sendRequest()

  writeFinishCallback:(res)=>
    if res == "ok"
      @log "write ok"
      # Publish the file to other users
      @cmd "sitePublish", {"inner_path": @myDataPath}, (res) =>
        if res == 'ok'
          @log "publish ok"
          document.getElementById("message").disabled = false
          document.getElementById("message").focus()
        else
          #TODO  revert UI
          @log "publish failed"
    else
      @cmd "wrapperNotification", ["error", "File write error: #{res}"]
      document.getElementById("message").disabled = false


  sendRequest:()=>
    @myData.id=@next_id
    @writeData @writeFinishCallback
      

  setSiteInfo:(site_info)=>
    @log "site_info",site_info
    @site_info = site_info
    @event_site_info.resolve(site_info)


  selectUser: =>
    Page.cmd "certSelect", [["zeroid.bit", "zeroverse.bit"]]
    return false


  route: (cmd, message) ->
    if cmd == "setSiteInfo"
      if message.params.cert_user_id
        document.getElementById("select_user").innerHTML = message.params.cert_user_id
      else
        document.getElementById("select_user").innerHTML = "Select user"
      @setSiteInfo(message.params)

      if @site_info.event?[0] == "file_done" and
        @site_info.event[1].match /data\/users\/#{@myPusherPath}\/data.json$/
          @receiveResponse()
    else
      @log cmd,message


  sendMessage: =>
    if not Page.site_info.cert_user_id  # No account selected, display error
      Page.cmd "wrapperNotification", ["info", "you must login first to play this game"]
      return

    $("#message").disabled = true

    @sendRequest({"cmd":$("#message").text()})



  addLine: (line) ->
    messages = document.getElementById("messages")
    messages.innerHTML = "<li>#{line}</li>"+messages.innerHTML


  # Wrapper websocket connection ready
  onOpenWebsocket: (e) =>
    @cmd "siteInfo", {}, (site_info) =>
      # Update currently selected username
      @setSiteInfo(site_info)
      if site_info.cert_user_id
        document.getElementById("select_user").innerHTML = site_info.cert_user_id

    @log "get server info"
    @cmd "serverInfo", {}, (ret) => # Get server info
      @log "server info getted",ret
      @server_info = ret
      if @server_info.rev < 160
        @cmd "wrapperNotification", ["error",
        "game requires at least ZeroNet 0.3.0 Please upgade!"]
        return

window.Page = new ZeroChat()
