export interface ExerciseData {
  id: string;
  name: string;
  bodyPart: string;
  equipment: string;
  gifUrl: string;
  target: string;
  secondaryMuscles: string[];
  instructions: string[];
}

export const INITIAL_EXERCISES: ExerciseData[] = [
  {
    id: "0025",
    name: "barbell bench press",
    bodyPart: "chest",
    equipment: "barbell",
    gifUrl: "https://v2.exercisedb.io/image/9Z7KjV4v-B9z8l",
    target: "pectorals",
    secondaryMuscles: ["triceps", "anterior deltoids"],
    instructions: [
      "Lie back on a flat bench with your feet flat on the ground.",
      "Grip the barbell with hands slightly wider than shoulder-width apart.",
      "Unrack the barbell and lower it slowly towards your mid-chest while keeping elbows at about 45 degrees.",
      "Press the bar back up to the starting position until arms are fully extended.",
      "Repeat for desired repetitions, then carefully rack the barbell."
    ]
  },
  {
    id: "0033",
    name: "barbell incline bench press",
    bodyPart: "chest",
    equipment: "barbell",
    gifUrl: "https://v2.exercisedb.io/image/Y9wB5YmR4c6fGg",
    target: "pectorals",
    secondaryMuscles: ["shoulders", "triceps"],
    instructions: [
      "Lie on an incline bench set to an angle of 30 to 45 degrees.",
      "Grasp the barbell with an overhand grip slightly wider than shoulder-width.",
      "Lower the bar smoothly toward your upper chest.",
      "Drive the bar straight back up to arm's length.",
      "Keep your shoulder blades retracted and feet planted."
    ]
  },
  {
    id: "0289",
    name: "dumbbell bench press",
    bodyPart: "chest",
    equipment: "dumbbell",
    gifUrl: "https://v2.exercisedb.io/image/X8vC7BnM1s9fLp",
    target: "pectorals",
    secondaryMuscles: ["triceps", "deltoids"],
    instructions: [
      "Sit on the edge of a flat bench with dumbbells resting on your knees.",
      "Lie back and bring dumbbells to the sides of your chest with palms forward.",
      "Press the weights upward until your arms are straight but not locked.",
      "Lower the dumbbells with control until you feel a deep stretch in the chest.",
      "Repeat for the specified number of sets and reps."
    ]
  },
  {
    id: "0662",
    name: "push-up",
    bodyPart: "chest",
    equipment: "body weight",
    gifUrl: "https://v2.exercisedb.io/image/A1bC2dE3fG4hIj",
    target: "pectorals",
    secondaryMuscles: ["triceps", "core", "shoulders"],
    instructions: [
      "Place your hands on the ground slightly wider than shoulder-width.",
      "Extend your legs behind you with a neutral spine and tight core.",
      "Lower your body until your chest almost touches the floor.",
      "Push forcefully through your palms to return to starting plank position.",
      "Maintain a straight line from head to heels throughout."
    ]
  },
  {
    id: "0027",
    name: "barbell deadlift",
    bodyPart: "back",
    equipment: "barbell",
    gifUrl: "https://v2.exercisedb.io/image/K3jH2gF1dE9sAw",
    target: "glutes",
    secondaryMuscles: ["hamstrings", "lower back", "lats", "forearms"],
    instructions: [
      "Stand with feet hip-width apart, barbell over midfoot.",
      "Hinge at the hips and bend knees to grip the bar just outside your shins.",
      "Set your back flat, chest tall, and engage your lats.",
      "Drive through the floor with your legs, keeping the bar close to your body.",
      "Stand fully upright, locking hips and knees without hyper-extending the spine.",
      "Hinge hips back and lower the bar under control."
    ]
  },
  {
    id: "0022",
    name: "barbell bent over row",
    bodyPart: "back",
    equipment: "barbell",
    gifUrl: "https://v2.exercisedb.io/image/L7mN8bV9cX2zAs",
    target: "upper back",
    secondaryMuscles: ["biceps", "lats", "rear deltoids"],
    instructions: [
      "Hold a barbell with a shoulder-width pronated grip.",
      "Bend knees slightly and hinge torso forward until nearly parallel to the floor.",
      "Pull the bar towards your lower ribcage, squeezing your shoulder blades together.",
      "Pause momentarily at peak contraction.",
      "Lower the barbell under control back to the starting hanging position."
    ]
  },
  {
    id: "0652",
    name: "pull-up",
    bodyPart: "back",
    equipment: "body weight",
    gifUrl: "https://v2.exercisedb.io/image/P4oI5uY6tR7eWq",
    target: "lats",
    secondaryMuscles: ["biceps", "rhomboids", "middle back"],
    instructions: [
      "Grasp the pull-up bar with an overhand grip wider than shoulder-width.",
      "Hang with arms fully extended and core engaged.",
      "Pull yourself upward by driving your elbows down toward your ribs.",
      "Continue pulling until your chin clears the bar.",
      "Lower yourself down slowly with full control to the starting dead hang."
    ]
  },
  {
    id: "0261",
    name: "cable lat pulldown",
    bodyPart: "back",
    equipment: "cable",
    gifUrl: "https://v2.exercisedb.io/image/Q1wE2rT3yU4iOp",
    target: "lats",
    secondaryMuscles: ["biceps", "rear deltoids"],
    instructions: [
      "Sit on the lat pulldown machine and adjust the thigh pad securely.",
      "Grip the wide bar with palms facing away from you.",
      "Slightly lean back (10-15 degrees) and draw the bar down to your upper chest.",
      "Focus on squeezing your lat muscles at the bottom.",
      "Return the bar slowly to full stretch overhead."
    ]
  },
  {
    id: "0043",
    name: "barbell overhead press",
    bodyPart: "shoulders",
    equipment: "barbell",
    gifUrl: "https://v2.exercisedb.io/image/Z9xX8c7v6b5n4m",
    target: "deltoids",
    secondaryMuscles: ["triceps", "upper chest", "core"],
    instructions: [
      "Stand with feet shoulder-width apart, holding the barbell across your clavicles.",
      "Brace your core, squeeze your glutes, and press the bar straight upward.",
      "Tilt head slightly back as the bar passes your chin, then push head forward once cleared.",
      "Lock out overhead with bar directly aligned over midfoot.",
      "Lower under control back to the collarbone shelf."
    ]
  },
  {
    id: "0334",
    name: "dumbbell lateral raise",
    bodyPart: "shoulders",
    equipment: "dumbbell",
    gifUrl: "https://v2.exercisedb.io/image/M5nB6vC7xZ8lKj",
    target: "deltoids",
    secondaryMuscles: ["traps"],
    instructions: [
      "Stand upright holding dumbbells at your sides, palms facing inward.",
      "With a slight bend in your elbows, raise arms out to the sides.",
      "Lift until arms are parallel to the ground (shoulder height).",
      "Pause for a split second at the top.",
      "Lower slowly back to starting position."
    ]
  },
  {
    id: "0031",
    name: "barbell bicep curl",
    bodyPart: "upper arms",
    equipment: "barbell",
    gifUrl: "https://v2.exercisedb.io/image/H8gF7dS6aP5oIu",
    target: "biceps",
    secondaryMuscles: ["forearms"],
    instructions: [
      "Stand upright holding a barbell with shoulder-width underhand grip.",
      "Keep elbows close to your torso and tuck your shoulders back.",
      "Curl the weights upward while contracting your biceps.",
      "Hold the contracted position briefly at top height.",
      "Lower the bar back down with smooth control."
    ]
  },
  {
    id: "0241",
    name: "cable triceps pushdown",
    bodyPart: "upper arms",
    equipment: "cable",
    gifUrl: "https://v2.exercisedb.io/image/U7yT6rE5wQ4iOk",
    target: "triceps",
    secondaryMuscles: ["forearms"],
    instructions: [
      "Attach a straight bar or rope to a high pulley.",
      "Grip the attachment with elbows bent at 90 degrees tucked to your sides.",
      "Push the attachment down by extending your elbows until arms are straight.",
      "Contract triceps firmly at the bottom.",
      "Allow the cable to return slowly up to 90 degrees."
    ]
  },
  {
    id: "0047",
    name: "barbell back squat",
    bodyPart: "upper legs",
    equipment: "barbell",
    gifUrl: "https://v2.exercisedb.io/image/V3bN2mK1lO9pIu",
    target: "quads",
    secondaryMuscles: ["glutes", "hamstrings", "calves", "core"],
    instructions: [
      "Rest the barbell securely across your upper traps.",
      "Position feet shoulder-width apart with toes turned slightly outward.",
      "Brace core and sit your hips back and down as if sitting in a chair.",
      "Descend until hips are below knee level (parallel or deeper).",
      "Drive through your heels to stand back up to starting position."
    ]
  },
  {
    id: "0052",
    name: "barbell romanian deadlift",
    bodyPart: "upper legs",
    equipment: "barbell",
    gifUrl: "https://v2.exercisedb.io/image/T6rE5wQ4iO3pLa",
    target: "hamstrings",
    secondaryMuscles: ["glutes", "lower back"],
    instructions: [
      "Hold a barbell at hip height with an overhand grip.",
      "Keep a slight, fixed bend in your knees throughout the movement.",
      "Hinge backward at the hips, lowering the bar along your thighs and shins.",
      "Stop when you feel a strong hamstring stretch, keeping back flat.",
      "Drive hips forward to return to standing lockout."
    ]
  },
  {
    id: "0001",
    name: "3/4 sit-up",
    bodyPart: "waist",
    equipment: "body weight",
    gifUrl: "https://v2.exercisedb.io/image/W1eR2tY3uI4oPa",
    target: "abs",
    secondaryMuscles: ["hip flexors", "lower back"],
    instructions: [
      "Lie flat on your back with knees bent and feet planted.",
      "Place fingers lightly beside your temples.",
      "Engage your abdominal muscles and raise your upper torso off the floor.",
      "Stop when three-quarters of the way up to maintain tension.",
      "Lower slowly back down without letting shoulder blades relax completely."
    ]
  },
  {
    id: "0443",
    name: "dumbbell lunges",
    bodyPart: "upper legs",
    equipment: "dumbbell",
    gifUrl: "https://v2.exercisedb.io/image/D8fG7hJ6kL5mNb",
    target: "quads",
    secondaryMuscles: ["glutes", "hamstrings", "calves"],
    instructions: [
      "Hold a pair of dumbbells at your sides with neutral grip.",
      "Step forward with one leg and lower your hips until both knees form 90-degree angles.",
      "Ensure front knee does not track excessively past toes.",
      "Push off the front foot to return to standing position.",
      "Repeat on the alternate leg."
    ]
  },
  {
    id: "0301",
    name: "dumbbell hammer curl",
    bodyPart: "upper arms",
    equipment: "dumbbell",
    gifUrl: "https://v2.exercisedb.io/image/C9vB8nM7lK6jHg",
    target: "biceps",
    secondaryMuscles: ["brachialis", "forearms"],
    instructions: [
      "Stand holding dumbbells at sides with palms facing each other (neutral grip).",
      "Keep upper arms still and curl weights upward towards shoulders.",
      "Squeeze biceps and forearms at the top of the lift.",
      "Lower dumbbells back with control to starting position."
    ]
  },
  {
    id: "0108",
    name: "cable face pull",
    bodyPart: "shoulders",
    equipment: "cable",
    gifUrl: "https://v2.exercisedb.io/image/B2nM3kL4jH5gFd",
    target: "rear deltoids",
    secondaryMuscles: ["traps", "rotator cuff", "rhomboids"],
    instructions: [
      "Attach a rope attachment to a cable machine set at upper chest level.",
      "Hold the rope ends with thumbs pointing backwards.",
      "Step back and pull the rope toward your face while separating your hands.",
      "Rotate wrists and pinch shoulder blades together at end range.",
      "Slowly extend arms to return to initial stretch."
    ]
  },
  {
    id: "0585",
    name: "leg press",
    bodyPart: "upper legs",
    equipment: "leverage machine",
    gifUrl: "https://v2.exercisedb.io/image/N7bV8cX9zA1sD2",
    target: "quads",
    secondaryMuscles: ["glutes", "hamstrings"],
    instructions: [
      "Sit back firmly in the leg press seat with feet shoulder-width on the platform.",
      "Disengage safety levers and bend knees to lower the sled smoothly.",
      "Lower until knees reach a 90-degree angle.",
      "Press through your whole foot to push the platform back up, without locking knees.",
      "Re-engage safety bars upon set completion."
    ]
  },
  {
    id: "0601",
    name: "plank",
    bodyPart: "waist",
    equipment: "body weight",
    gifUrl: "https://v2.exercisedb.io/image/E4rT5yU6iO7pL8",
    target: "abs",
    secondaryMuscles: ["core", "shoulders", "glutes"],
    instructions: [
      "Place forearms on the floor with elbows directly under shoulders.",
      "Extend legs behind you with toes touching the ground.",
      "Keep body in a rigid, straight line from shoulders to heels.",
      "Contract abdominals and glutes, preventing hips from sagging or hiking.",
      "Hold position steadily while breathing continuously."
    ]
  }
];
