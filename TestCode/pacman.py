import pygame
import random

# Initialize Pygame
pygame.init()

# Set up the game window
WINDOW_WIDTH = 800
WINDOW_HEIGHT = 600
window = pygame.display.set_mode((WINDOW_WIDTH, WINDOW_height))
pygame.display.set_caption("Pac-Man")

# Define colors
BLACK = (0, 0, 0)
WHITE = (255, 255, 255)
YELLOW = (255, 255, 0)
BLUE = (0, 0, 255)

# Define game objects
class Pacman(pygame.sprite.Sprite):
    def __init__(self, x, y):
        super().__init__()
        self.image = pygame.Surface([20, 20])
        self.image.fill(YELLOW)
        self.rect = self.image.get_rect()
        self.rect.x = x
        self.rect.y = y
        self.speed = 5

    def move(self, dx, dy):
        self.rect.x += dx
        self.rect.y += dy

        # Keep Pac-Man within the game window
        self.rect.clamp_ip(window.get_rect())

class Ghost(pygame.sprite.Sprite):
    def __init__(self, x, y, color):
        super().__init__()
        self.image = pygame.Surface([20, 20])
        self.image.fill(color)
        self.rect = self.image.get_rect()
        self.rect.x = x
        self.rect.y = y
        self.speed = 3
        self.direction = random.choice([-1, 1])

    def move(self):
        if self.direction == -1:
            self.rect.x -= self.speed
        else:
            self.rect.x += self.speed

        # Reverse direction when reaching the edge of the screen
        if self.rect.left <= 0 or self.rect.right >= WINDOW_WIDTH:
            self.direction *= -1

# Game loop
running = True
pacman = Pacman(400, 300)
ghosts = [
    Ghost(100, 100, BLUE),
    Ghost(700, 100, BLUE),
    Ghost(100, 500, BLUE),
    Ghost(700, 500, BLUE)
]

while running:
    # Handle events
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

    # Move Pac-Man
    keys = pygame.key.get_pressed()
    if keys[pygame.K_LEFT]:
        pacman.move(-pacman.speed, 0)
    if keys[pygame.K_RIGHT]:
        pacman.move(pacman.speed, 0)
    if keys[pygame.K_UP]:
        pacman.move(0, -pacman.speed)
    if keys[pygame.K_DOWN]:
        pacman.move(0, pacman.speed)

    # Move ghosts
    for ghost in ghosts:
        ghost.move()

    # Clear the screen
    window.fill(BLACK)

    # Draw Pac-Man and ghosts
    window.blit(pacman.image, pacman.rect)
    for ghost in ghosts:
        window.blit(ghost.image, ghost.rect)

    # Update the display
    pygame.display.flip()

# Quit Pygame
pygame.quit()