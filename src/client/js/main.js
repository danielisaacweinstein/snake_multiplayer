;(function() {

  var BLOCK_SIZE = 10;

  var Game = function() {
    var screen = document.getElementById("screen").getContext('2d');

    this.socket = new WebSocket('ws://localhost:4567');
    this.dataReceived = null;

    var keyhandler = new Keyboarder(this.socket);

    // this.mockupData = {
    //   board: {size: {width: 310, height: 310}},
    //   snakes: [
    //     {
    //       headblock: { center: {x: 100, y: 100}, color: 'black', size: {x: 10, y: 10} },
    //       bodyblocks: [
    //         { center: {x: 100, y: 110}, color: 'black', size: {x: 10, y: 10} },
    //         { center: {x: 100, y: 120}, color: 'black', size: {x: 10, y: 10} },
    //         { center: {x: 90, y: 120}, color: 'black', size: {x: 10, y: 10} },
    //         { center: {x: 90, y: 130}, color: 'black', size: {x: 10, y: 10} }
    //       ]
    //     },
    //     {
    //       headblock: { center: {x: 20, y: 100}, color: 'black', size: {x: 10, y: 10} },
    //       bodyblocks: [
    //         { center: {x: 20, y: 110}, color: 'black', size: {x: 10, y: 10} },
    //         { center: {x: 20, y: 120}, color: 'black', size: {x: 10, y: 10} },
    //         { center: {x: 10, y: 120}, color: 'black', size: {x: 10, y: 10} },
    //         { center: {x: 10, y: 130}, color: 'black', size: {x: 10, y: 10} }
    //       ]
    //     }
    //   ]
    // };

    var self = this;
    this.socket.onopen = function() {
        this.isopen = true;
        console.log("Connected!");
    }

    this.socket.onmessage = function(e) {
      if (typeof e.data == "string") {
          self.dataReceived = JSON.parse(e.data);
          //self.dataReceived = self.mockupData;

          self.draw(screen);
          console.log(self.dataReceived);
      }
    }.bind(screen)

    this.socket.onclose = function(e) {
        console.log("Connection closed.");
        this.socket = null;
        this.isopen = false;
    }

    this.socket.sendMessage = function(data, type) {
      if (this.isopen) {
          switch(type) {
              case 'json':
                  this.send(JSON.stringify(data));
                  break;
              case 'string':
                  this.send(data);
                  break;
          }
      } else {
          console.log("Connection not opened.")
      }
    }
  };

  Game.prototype = {
    draw: function(screen) {
      data = this.dataReceived;

      // Clear screen
      screen.clearRect(0, 0, data.board.size.x, data.board.size.y);

      // Draw the bodies
      data.snakes.map(function(snake){
        drawRect(screen, snake.headblock, snake.headblock.color);
        snake.bodyblocks.map(function(bodyBlock){
          drawRect(screen, bodyBlock, bodyBlock.color);
        }.bind(screen));
      }.bind(screen));

      // Draw based on JSON from server
    }
  };


  var Keyboarder = function(socket) {
    var keyState = {};

    window.addEventListener('keydown', function(e) {
      keyState[e.keyCode] = true;
      socket.sendMessage(e.keyCode, "json");
      // console.log("key pressed!")
    });

    window.addEventListener('keyup', function(e) {
      keyState[e.keyCode] = false;
    });

    this.isDown = function(keyCode) {
      return keyState[keyCode] === true;
    };

    this.KEYS = { LEFT: 37, RIGHT: 39, UP: 38, DOWN: 40 };
  };


  var drawRect = function(screen, body, color) {
    screen.fillStyle = color;
    screen.fillRect(body.center.x - body.size.x / 2, body.center.y - body.size.y / 2,
                    body.size.x, body.size.y);
  };

  window.addEventListener('load', function() {
    new Game();
  });
})(this);
