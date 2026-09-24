import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Exercise } from './entities/exercise.entity.js';

@Module({
  imports: [TypeOrmModule.forFeature([Exercise])],
  exports: [TypeOrmModule],
})
export class ExercisesModule {}
