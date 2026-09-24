import { Injectable, Logger, NotFoundException, OnApplicationBootstrap } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, ILike } from 'typeorm';
import { ConfigService } from '@nestjs/config';
import { Cron, CronExpression } from '@nestjs/schedule';
import axios from 'axios';
import { Exercise } from './entities/exercise.entity.js';
import { INITIAL_EXERCISES } from './data/initial-exercises.js';
import { FindExercisesQueryDto } from './dto/find-exercises-query.dto.js';

@Injectable()
export class ExercisesService implements OnApplicationBootstrap {
  private readonly logger = new Logger(ExercisesService.name);

  constructor(
    @InjectRepository(Exercise)
    private readonly exerciseRepository: Repository<Exercise>,
    private readonly configService: ConfigService,
  ) {}

  async onApplicationBootstrap() {
    const count = await this.exerciseRepository.count();
    if (count === 0) {
      this.logger.log('Exercise database is empty. Initiating initial seeding...');
      await this.seedInitialData();
    } else {
      this.logger.log(`Exercise database already contains ${count} exercises.`);
    }
  }

  /**
   * Seed initial exercise data. If RapidAPI key is configured, attempts to fetch
   * from ExerciseDB. Otherwise or upon failure, seeds from curated dataset.
   */
  async seedInitialData(): Promise<{ message: string; count: number }> {
    const apiKey = this.configService.get<string>('RAPIDAPI_KEY');
    let seededCount = 0;

    if (apiKey && apiKey.trim().length > 0) {
      this.logger.log('RapidAPI key detected. Attempting to fetch initial data from ExerciseDB API...');
      try {
        const fetched = await this.fetchFromExerciseDB(0, 50);
        if (fetched.length > 0) {
          for (const item of fetched) {
            await this.upsertExercise(item);
            seededCount++;
          }
          this.logger.log(`Successfully seeded ${seededCount} exercises from ExerciseDB API.`);
          return { message: 'Seeded from ExerciseDB API', count: seededCount };
        }
      } catch (err: any) {
        this.logger.warn(`Failed to seed from ExerciseDB API: ${err.message}. Falling back to initial dataset.`);
      }
    }

    // Fallback or default initial dataset
    for (const item of INITIAL_EXERCISES) {
      await this.upsertExercise(item);
      seededCount++;
    }
    this.logger.log(`Seeded ${seededCount} exercises from curated local dataset.`);
    return { message: 'Seeded from curated dataset', count: seededCount };
  }

  /**
   * Periodic background synchronization (runs weekly on Sunday at 2 AM)
   */
  @Cron(CronExpression.EVERY_WEEK)
  async handleCronSync() {
    this.logger.log('Starting scheduled weekly sync with ExerciseDB API...');
    try {
      await this.syncWithExerciseDB();
    } catch (err: any) {
      this.logger.error(`Error during scheduled ExerciseDB sync: ${err.message}`);
    }
  }

  /**
   * Manual or scheduled sync with ExerciseDB API
   */
  async syncWithExerciseDB(): Promise<{ message: string; synced: number }> {
    const apiKey = this.configService.get<string>('RAPIDAPI_KEY');
    if (!apiKey || apiKey.trim().length === 0) {
      this.logger.warn('Sync skipped: RAPIDAPI_KEY is not configured.');
      return { message: 'RAPIDAPI_KEY is not configured in backend/.env', synced: 0 };
    }

    let totalSynced = 0;
    let offset = 0;
    const limit = 50;

    // Fetch in batches respecting rate limits
    while (offset < 200) {
      try {
        const batch = await this.fetchFromExerciseDB(offset, limit);
        if (!batch || batch.length === 0) break;

        for (const item of batch) {
          await this.upsertExercise(item);
          totalSynced++;
        }

        offset += limit;
        // Pause briefly between batches to respect rate limits
        await new Promise((resolve) => setTimeout(resolve, 1000));
      } catch (err: any) {
        this.logger.error(`Batch sync failed at offset ${offset}: ${err.message}`);
        break;
      }
    }

    this.logger.log(`ExerciseDB sync finished. Total exercises updated: ${totalSynced}`);
    return { message: 'Synchronization completed', synced: totalSynced };
  }

  private async fetchFromExerciseDB(offset = 0, limit = 50): Promise<any[]> {
    const baseUrl = this.configService.get<string>('EXERCISE_DB_API_URL', 'https://exercisedb.p.rapidapi.com');
    const apiKey = this.configService.get<string>('RAPIDAPI_KEY');
    const apiHost = this.configService.get<string>('RAPIDAPI_HOST', 'exercisedb.p.rapidapi.com');

    const response = await axios.get(`${baseUrl}/exercises`, {
      params: { offset, limit },
      headers: {
        'x-rapidapi-key': apiKey,
        'x-rapidapi-host': apiHost,
      },
      timeout: 10000,
    });

    return response.data || [];
  }

  private async upsertExercise(item: any): Promise<Exercise> {
    const exercise = this.exerciseRepository.create({
      id: String(item.id),
      name: item.name,
      bodyPart: item.bodyPart,
      equipment: item.equipment,
      gifUrl: item.gifUrl,
      target: item.target,
      secondaryMuscles: item.secondaryMuscles || [],
      instructions: item.instructions || [],
    });
    return this.exerciseRepository.save(exercise);
  }

  async findAll(query: FindExercisesQueryDto) {
    const limit = Math.min(Number(query.limit) || 50, 100);
    const offset = Number(query.offset) || 0;

    const queryBuilder = this.exerciseRepository.createQueryBuilder('exercise');

    if (query.search) {
      queryBuilder.andWhere('exercise.name ILIKE :search', {
        search: `%${query.search.toLowerCase()}%`,
      });
    }

    if (query.bodyPart) {
      queryBuilder.andWhere('LOWER(exercise.bodyPart) = :bodyPart', {
        bodyPart: query.bodyPart.toLowerCase(),
      });
    }

    if (query.target) {
      queryBuilder.andWhere('LOWER(exercise.target) = :target', {
        target: query.target.toLowerCase(),
      });
    }

    if (query.equipment) {
      queryBuilder.andWhere('LOWER(exercise.equipment) = :equipment', {
        equipment: query.equipment.toLowerCase(),
      });
    }

    queryBuilder.orderBy('exercise.name', 'ASC');
    queryBuilder.skip(offset).take(limit);

    const [data, total] = await queryBuilder.getManyAndCount();

    return {
      data,
      total,
      limit,
      offset,
      page: Math.floor(offset / limit) + 1,
    };
  }

  async findOne(id: string): Promise<Exercise> {
    const exercise = await this.exerciseRepository.findOne({ where: { id } });
    if (!exercise) {
      throw new NotFoundException(`Exercise with ID "${id}" not found`);
    }
    return exercise;
  }

  async getBodyParts(): Promise<string[]> {
    const results = await this.exerciseRepository
      .createQueryBuilder('exercise')
      .select('DISTINCT exercise.bodyPart', 'bodyPart')
      .orderBy('exercise.bodyPart', 'ASC')
      .getRawMany();
    return results.map((r) => r.bodyPart).filter(Boolean);
  }

  async getTargets(): Promise<string[]> {
    const results = await this.exerciseRepository
      .createQueryBuilder('exercise')
      .select('DISTINCT exercise.target', 'target')
      .orderBy('exercise.target', 'ASC')
      .getRawMany();
    return results.map((r) => r.target).filter(Boolean);
  }

  async getEquipments(): Promise<string[]> {
    const results = await this.exerciseRepository
      .createQueryBuilder('exercise')
      .select('DISTINCT exercise.equipment', 'equipment')
      .orderBy('exercise.equipment', 'ASC')
      .getRawMany();
    return results.map((r) => r.equipment).filter(Boolean);
  }
}
