import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Exercise } from './entities/exercise.entity.js';
import { ExercisesService } from './exercises.service.js';
import { ExercisesController } from './exercises.controller.js';

@Module({
  imports: [TypeOrmModule.forFeature([Exercise])],
  controllers: [ExercisesController],
  providers: [ExercisesService],
  exports: [ExercisesService, TypeOrmModule],
})
export class ExercisesModule {}
