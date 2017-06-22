//
//  GameScene.swift
//  HoppyBunny3
//
//  Created by Cappillen on 6/20/17.
//  Copyright © 2017 Cappillen. All rights reserved.
//

import SpriteKit
import GameplayKit

enum GameState {
    case menu, active, gameOver
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var bugs: SKSpriteNode!
    var sinceTouch: CFTimeInterval = 0
    let fixedDelta: CFTimeInterval = 1.0/60.0 //60 fps
    let scrollSpd: CGFloat = 100
    var scrollLayer: SKNode!
    var scrollLayer2: SKNode!
    var scrollLayer3: SKNode!
    var obstacleSource: SKNode!
    var spawnTimer: CFTimeInterval = 0
    var obstaclelayer: SKNode!
    var buttonRestart: MSButtonNode!
    var buttonPlay: MSButtonNode!
    var gameState: GameState = .menu
    var scoreLabel: SKLabelNode!
    var points = 0
    
    override func didMove(to view: SKView) {
        /* Setup your scene here*/
        
        //recursive search for the bug
        bugs = self.childNode(withName: "//bugs") as! SKSpriteNode
        
        //Set reference to the scrollLayer nodes
        scrollLayer = self.childNode(withName: "scrollLayer")
        scrollLayer2 = self.childNode(withName: "scrollLayer2")
        scrollLayer3 = self.childNode(withName: "scrollLayer3")
        obstacleSource = self.childNode(withName: "obstacle")
        obstaclelayer = self.childNode(withName: "obstacleLayer")
        
        //Set UI connections

        //Setup for the buttonRestart selection handler
        buttonPlay = self.childNode(withName: "buttonPlay") as! MSButtonNode
        
        buttonPlay.selectedHandler = {
            
            self.gameState = .active
            
            self.bugs.physicsBody?.isDynamic = true
            
        }
        
        buttonRestart = self.childNode(withName: "buttonRestart") as! MSButtonNode
        
        //Setup for the buttonRestart selection handler
        buttonRestart.selectedHandler = {
            
            //Grab reference to the SpriteKit view
            let skView = self.view as SKView!
            
            //Gran reference to the GameScene
            let scene = GameScene(fileNamed: "GameScene") as GameScene!
            
            //Ensure the correct aspect mode
            scene?.scaleMode = .aspectFill
            
            //Restart the scene - load the scene
            skView?.presentScene(scene)
        }
        
        //get access to the contact deleagates - in other words contacts
        physicsWorld.contactDelegate = self
        
        //Hide the button 
        buttonRestart.state = MSButtonNodeState.Hidden
        
        scoreLabel = self.childNode(withName: "scoreLabel") as! SKLabelNode
        
        //Reset score Label
        scoreLabel.text = "\(points)"
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Called when a touch began */
        
        //Check gameState if game is active
        if gameState != .active { return }
        
        //Reset velocity, helps improve response against cumulative falling velocity - makes the jump a bit more smooth
        bugs.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        
        //Gives a jump to the bunny
        bugs.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 300))
        
        //Add SFX
        let flapSFX = SKAction.playSoundFileNamed("sfx_flap", waitForCompletion: false)
        self.run(flapSFX)
        
        //Adds rotation to the bunny
        bugs.physicsBody?.applyAngularImpulse(1)
        
        //Resets timer sinceTouch
        sinceTouch = 0
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        /* Called before each frame is rendered */
        
        //Check gameState if game is active
        if gameState != .active { return }
        
        if gameState == .active || gameState == .gameOver {
            buttonPlay.state = MSButtonNodeState.Hidden
        }
        
        //print("PositionX: \(bugs.position.y)")
        //print("Velocity: \(bugs.physicsBody!.velocity.dy)")
        
        let velocityY = bugs.physicsBody?.velocity.dy ?? 0
        let positionY = bugs.position.y
        
        //Check vertical impulse 
        if velocityY > 400 {
            bugs.physicsBody?.velocity.dy = 400
        }
        
        //Check position
        if positionY > 400 {
            bugs.position.y = 400
        }
        
        //Applying rotation
        if sinceTouch > 0.2 {
            let impulse = -20000 * fixedDelta
            bugs.physicsBody?.applyAngularImpulse(CGFloat(impulse))
        }
        
        //Clamp rotation
        bugs.zRotation.clamp(v1: CGFloat(-90).degreesToRadians(), CGFloat(30).degreesToRadians())
        bugs.physicsBody?.angularVelocity.clamp(v1: -3, 3)
        
        //update Timer
        sinceTouch += fixedDelta
        
        //Scrolling the world
        scrollEntireWorld()
        
        //Update obstacles
        updateObstacles()
        
        //Update spawnTimer
        spawnTimer += fixedDelta
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        //Called when bugs hits an object with the physic properties
        
        //Ensure only called when the game is running 
        if gameState != .active { return }
        
        //Get references to the bodies involved in the collision
        let contactA = contact.bodyA
        let contactB = contact.bodyB
        
        //Get references to the physics body parent nodes
        let nodeA = contactA.node!
        let nodeB = contactB.node!
        
        //Did the hero pass through the goal?
        if nodeA.name == "goal" || nodeB.name == "goal" {
            
            //increment points
            points += 1
            
            //Update ScoreLbael
            scoreLabel.text = String(points)
            
            let flapSFX = SKAction.playSoundFileNamed("sfx_goal", waitForCompletion: false)
            self.run(flapSFX)
            //We can exit now we added points and don't want to die
            return
        }
        
        //Change gameState to game over
        gameState = .gameOver
        
        //Stop any new angular velocity being applied
        bugs.physicsBody?.allowsRotation = false
        
        //Reset angular velocity
        bugs.physicsBody?.angularVelocity = 0
        
        //Stop hero flapping animation
        bugs.removeAllActions()
        
        //Show restart button
        buttonRestart.state = MSButtonNodeState.Active
        
        //Create our hero's DeathScene
        let heroDeath = SKAction.run({
            
            //Put our hero facing down in the dirt
            self.bugs.zRotation = CGFloat(-90).degreesToRadians()
        })
        
        //Run the Action
        bugs.run(heroDeath)
        
        let shakeScene: SKAction = SKAction.init(named: "ShakeItUp")!
        
        //Loop through all the nodes
        for node in self.children {
            
            //Apply the shake to the scene
            node.run(shakeScene)
        }
        
    }
    func scroller(node: SKNode, spd: CGFloat) {
        //Scroll array
        node.position.x -= spd * CGFloat(fixedDelta)
        
        //Loopin the ground
        for object in node.children as! [SKSpriteNode] {
            
            let objectPosition = node.convert(object.position, to: self)
            
            if objectPosition.x <= -object.size.width / 2 {
                
                let newPosition = CGPoint(x: (self.size.width / 2) + object.size.width, y: objectPosition.y)
                
                object.position = self.convert(newPosition, to: node)
            }
        }
        
    }
    
    func scrollEntireWorld() {
        
        //Scroll ground
        scroller(node: scrollLayer, spd: 100)
        //Scroll sky
        scroller(node: scrollLayer2, spd: 90)
        //Scroll ice
        scroller(node: scrollLayer3, spd: 80)
    }
    
    func scrollWorld() {
        //Scroll world
        
        scrollLayer.position.x -= scrollSpd * CGFloat(fixedDelta)
        
        //Loop the ground
        for ground in scrollLayer.children as! [SKSpriteNode] {
            //Gets position
            let groundPosition = scrollLayer.convert(ground.position, to: self)
            
            //check if ground is out of the scene
            //width is 460/2 = 230 -> -230 is when its position reaches there then reset
            if groundPosition.x <= -ground.size.width / 2 {
                
                //Reposition ground sprite to its new position
                let newPosition = CGPoint(x: (self.size.width / 2) + ground.size.width, y: groundPosition.y)
                
                //Add new position
                ground.position = self.convert(newPosition, to: scrollLayer)
            }
            
            
        }
    }
    
    func scrollSky() {
        //Scroll Clouds if possible
        
        scrollLayer2.position.x -= (scrollSpd - 10) * CGFloat(fixedDelta)
        
        //Loop the sky
        for cloud in scrollLayer2.children as! [SKSpriteNode] {
//            //Gets position
            let cloudPosition = scrollLayer2.convert(cloud.position, to: self)
            
            //Check if cloud is out of the scene 
            //works just like the ground
            if cloudPosition.x <= -cloud.size.width / 2 {
                
                //Make new position for the new cloud
                let newCloudPosition = CGPoint(x: (self.size.width / 2) + cloud.size.width, y: cloudPosition.y)
                
                //Add new position
                cloud.position = self.convert(newCloudPosition, to: scrollLayer2)
            }
        }
    }
    
    func updateObstacles() {
        /* Update obstacles*/
        
        obstaclelayer.position.x -= scrollSpd * CGFloat(fixedDelta)
        
        //Loop through the obstacle layer nodes
        for obstacle in obstaclelayer.children as! [SKReferenceNode] {
            
            //Set reference to the obstacle position
            let obstaclePosition = obstaclelayer.convert(obstacle.position, to: self)
            
            //Check if the obstacle left the scene
            if obstaclePosition.x <= -26 {
                //26 if half of the objects width
                
                //Remove the obstacle node
                obstacle.removeFromParent()
            }
        }
        //Add new obstacles
        if spawnTimer >= 1.5 {
            
            //Set reference of the new obstacle
            let newObstacle = obstacleSource.copy() as! SKNode
            obstaclelayer.addChild(newObstacle)
            
            //Generate new random y position
            let randomPosition = CGPoint(x: 352, y: CGFloat.random(min: 234, max: 382))
            
            //Converts new obstacles position to the new position to the obstacle layer 
            newObstacle.position = self.convert(randomPosition, to: obstaclelayer)
            
            //Reset Timer
            spawnTimer = 0
            
        }
    }
}
