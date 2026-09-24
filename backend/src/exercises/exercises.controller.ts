import { Controller, Get, Post, Param, Query } from '@nestjs/common';
import { ExercisesService } from './exercises.service.js';
import { FindExercisesQueryDto } from './dto/find-exercises-query.dto.js';

@Controller('exercises')
export class ExercisesController {
  constructor(private readonly exercisesService: ExercisesService) {}

  @Get('bodyParts')
  getBodyParts() {
    return this.exercisesService.getBodyParts();
  }

  @Get('targets')
  getTargets() {
    return this.exercisesService.getTargets();
  }

  @Get('equipments')
  getEquipments() {
    return this.exercisesService.getEquipments();
  }

  @Post('sync')
  sync() {
    return this.exercisesService.syncWithExerciseDB();
  }

  @Post('seed')
  seed() {
    return this.exercisesService.seedInitialData();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.exercisesService.findOne(id);
  }

  @Get()
  findAll(@Query() query: FindExercisesQueryDto) {
    return this.exercisesService.findAll(query);
  }
}
