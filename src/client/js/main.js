;(function() {
    
  var BLOCK_SIZE = 10;

  var Game = function() {
    var screen = document.getElementById("screen").getContext('2d');

    this.size = { x: screen.canvas.width, y: screen.canvas.height };
    this.center = { x: this.size.x / 2, y: this.size.y / 2 };
    
    
    this.client = new Faye.Client('http://localhost:4567/faye');    
    this.publication = this.client.publish('/foo', {text: 'Hi there'});
    this.publication.then(function() {
      console.log('Message received by server!');
    }, function(error) {
      console.log('There was a problem: ' + error.message);
    });
    
    this.bodies = [new HeadBlock(this)];
    this.currentDirection = null;
    
    var self = this;
    var tick = function() {
      self.update();
      self.draw(screen);
      requestAnimationFrame(tick);
    };

    tick();
  };

  Game.prototype = {
    update: function() {
      for (var i = 0; i < this.bodies.length; i++) {
        if (this.bodies[i].update !== undefined) {
          this.bodies[i].update();
        }
      }
    },

    draw: function(screen) {
      screen.clearRect(0, 0, this.size.x, this.size.y);
      for (var i = 0; i < this.bodies.length; i++) {
        this.bodies[i].draw(screen);
      }
    }
  };
  
  var HeadBlock = function(game) {
    this.game = game;
    this.center = { x: this.game.center.x, y: this.game.center.y };
    this.direction = { x: 1, y: 0 };
    this.moveReady = false;
    this.size = { x: BLOCK_SIZE, y: BLOCK_SIZE };
    this.blocks = [];

    this.keyboarder = new Keyboarder();
    this.lastMove = 0;

    this.addBlock = false;
  };
  
  HeadBlock.prototype = {
    update: function() {
      this.handleKeyboard();

      var now = new Date().getTime();
      if ((now > this.lastMove + 100) && (this.moveReady === true)) {
        this.game.currentDirection = this.direction;
        
        this.move();
        this.lastMove = now;
        this.moveReady = false;
      }
    },

    draw: function(screen) {
      drawRect(screen, this, "black");
    },

    handleKeyboard: function() {
      if (this.keyboarder.isDown(this.keyboarder.KEYS.LEFT) &&
          this.direction.x !== 1) {
        this.direction.x = -1;
        this.direction.y = 0;
        this.moveReady = true;
      } else if (this.keyboarder.isDown(this.keyboarder.KEYS.RIGHT) &&
                 this.direction.x !== -1) {
        this.direction.x = 1;
        this.direction.y = 0;
        this.moveReady = true;
      }

      if (this.keyboarder.isDown(this.keyboarder.KEYS.UP) &&
          this.direction.y !== 1) {
        this.direction.y = -1;
        this.direction.x = 0;
        this.moveReady = true;
      } else if (this.keyboarder.isDown(this.keyboarder.KEYS.DOWN) &&
                 this.direction.y !== -1) {
        this.direction.y = 1;
        this.direction.x = 0;
        this.moveReady = true;
      }
    },

    move: function() {
      this.center.x += this.direction.x * BLOCK_SIZE;
      this.center.y += this.direction.y * BLOCK_SIZE;
    }
  };

  var Keyboarder = function() {
    var keyState = {};

    window.addEventListener('keydown', function(e) {
      keyState[e.keyCode] = true;
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