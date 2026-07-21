// Bright radial warp points for Ghostty + Herdr.
// This keeps the original center-out warp motion, but stars are born at random
// positions inside a large circular spawn zone. Crisp points only: no glow,
// trails, streaks, or twinkling.

const float TAU = 6.28318530718;
const float WARP_SPEED = 0.060;
const float SPAWN_RADIUS = 0.22;
const float STAR_BRIGHTNESS = 1.38;
const float BACKGROUND_LUMA_START = 0.11;
const float BACKGROUND_LUMA_END = 0.25;
const int STAR_COUNT = 44;

const vec3 STAR_COLOR = vec3(0.96, 0.98, 1.00);

float hash11(float value) {
    value = fract(value * 0.1031);
    value *= value + 33.33;
    value *= value + value;
    return fract(value);
}

float luminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 terminalColor = texture(iChannel0, uv);

    // Aspect-correct coordinates make SPAWN_RADIUS a true circle on screen.
    vec2 point = (fragCoord - iResolution.xy * 0.5) / iResolution.y;
    float pixel = 1.0 / iResolution.y;
    vec3 stars = vec3(0.0);

    for (int index = 0; index < STAR_COUNT; index++) {
        float id = float(index) + 1.0;
        float individualSpeed = mix(0.72, 1.28, hash11(id * 5.73 + 8.1));

        // A generation change gives every respawn a fresh random location in
        // the circular spawn zone rather than one shared center point.
        float timeline = hash11(id * 27.41) - iTime * WARP_SPEED * individualSpeed;
        float phase = fract(timeline);
        float generation = floor(timeline);
        float key = id * 47.17 + generation * 131.73;

        float z = mix(0.075, 1.0, phase);
        float approach = 1.0 - z;

        float angle = hash11(key + 4.7) * TAU;
        vec2 direction = vec2(cos(angle), sin(angle));

        // sqrt() distributes points uniformly by area instead of clustering
        // them at the middle of the spawn circle.
        float spawnDistance = SPAWN_RADIUS * sqrt(hash11(key + 13.9));
        vec2 spawnPosition = direction * spawnDistance;

        // Preserve the original perspective-style radial acceleration. Every
        // star follows its own ray from its randomized point in the spawn zone.
        float radialSeed = mix(0.07, 0.62, sqrt(hash11(key + 26.3)));
        float travelDistance = radialSeed * (1.0 / z - 1.0) * 0.255;
        vec2 position = spawnPosition + direction * travelDistance;

        float sizeVariation = hash11(key + 41.6);
        float radius = pixel * mix(
            mix(1.05, 1.45, sizeVariation),
            mix(2.85, 3.70, sizeVariation),
            pow(approach, 1.25)
        );

        float distanceToStar = length(point - position);

        // One antialiased solid point. There is deliberately no outer halo or
        // sampled previous position, so neither glow nor a trail can be drawn.
        float pointShape = 1.0 - smoothstep(radius * 0.36, radius, distanceToStar);

        // Fade only at lifecycle boundaries to avoid visible respawn popping.
        float fadeIn = 1.0 - smoothstep(0.88, 1.0, z);
        float fadeOut = smoothstep(0.075, 0.15, z);
        float life = fadeIn * fadeOut;
        float brightness = mix(0.86, 1.28, pow(approach, 0.75));

        stars += STAR_COLOR * pointShape * life * brightness;
    }

    // Draw only over dark terminal pixels so text, borders, and cursor effects
    // remain crisp and readable.
    float backgroundMask = 1.0 - smoothstep(
        BACKGROUND_LUMA_START,
        BACKGROUND_LUMA_END,
        luminance(terminalColor.rgb)
    );

    vec3 result = terminalColor.rgb + stars * STAR_BRIGHTNESS * backgroundMask;
    fragColor = vec4(min(result, vec3(1.0)), terminalColor.a);
}
